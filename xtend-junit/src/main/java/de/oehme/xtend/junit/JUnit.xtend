package de.oehme.xtend.junit 

import de.oehme.xtend.contrib.SignatureHelper
import org.eclipse.xtend.lib.macro.AbstractClassProcessor
import org.eclipse.xtend.lib.macro.Active
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.declaration.FieldDeclaration
import org.eclipse.xtend.lib.macro.declaration.MemberDeclaration
import org.eclipse.xtend.lib.macro.declaration.Modifier
import org.eclipse.xtend.lib.macro.declaration.MutableClassDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableFieldDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableMemberDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableMethodDeclaration
import org.eclipse.xtend.lib.macro.declaration.Visibility
import org.junit.Assert
import org.junit.Assume
import org.junit.Rule
import org.junit.Test
import org.junit.experimental.theories.DataPoint
import org.junit.experimental.theories.DataPoints
import org.junit.experimental.theories.Theories
import org.junit.experimental.theories.Theory
import org.junit.runner.RunWith

@Active(JUnitProcessor)
annotation JUnit {
}

class JUnitProcessor extends AbstractClassProcessor {
	var extension TransformationContext context
	var extension SignatureHelper signatures

	override doTransform(MutableClassDeclaration cls, TransformationContext context) {
		this.context = context
		signatures = new SignatureHelper(context)
		cls.handleTestMethods
		cls.handleRules
		cls.handleTheories
		cls.importAssert
		cls.importJUnitExtensions
	}

	def handleTestMethods(MutableClassDeclaration cls) {
		cls.declaredMethods.filter [
			visibility == Visibility.PUBLIC && 
			static == false && 
			findAnnotation(Theory.findTypeGlobally) == null &&
			findAnnotation(DataPoint.findTypeGlobally) == null &&
			findAnnotation(DataPoints.findTypeGlobally) == null
		].forEach [
			if (parameters.size != 0) {
				addError("Test methods cannot take parameters")
			}
			if (!returnType.isInferred && returnType != primitiveVoid) {
				addError("Test methods always return void, you can leave out the return type")
			}
			if (findAnnotation(Test.findTypeGlobally) == null) {
				addAnnotation(Test.newAnnotationReference)
			}
			returnType = primitiveVoid
		]
	}

	def handleRules(MutableClassDeclaration cls) {
		cls.declaredFields.filter [
			findAnnotation(Rule.findTypeGlobally) != null
		].forEach [
			val source = primarySourceElement as FieldDeclaration
			val forbiddenModifiers = #{Modifier.PRIVATE, Modifier.PROTECTED, Modifier.PACKAGE, Modifier.STATIC}
			for (mod : forbiddenModifiers) {
				if (source.modifiers.contains(mod)) {
					addError('''Rules cannot be «mod»''')
				}
			}
			visibility = Visibility.PUBLIC
		]
	}

	def handleTheories(MutableClassDeclaration cls) {
		val dataPointMembers = cls.declaredMembers.filter [
			findAnnotation(DataPoint.findTypeGlobally) != null
		]
		val dataPointsMembers = cls.declaredMembers.filter [
			findAnnotation(DataPoints.findTypeGlobally) != null
		]
		val theories = cls.declaredMethods.filter [
			findAnnotation(Theory.findTypeGlobally) != null
		]

		(dataPointMembers + dataPointsMembers).forEach [
			val source = primarySourceElement as MemberDeclaration
			val forbiddenModifiers = #{Modifier.PRIVATE, Modifier.PROTECTED, Modifier.PACKAGE}
			for (mod : forbiddenModifiers) {
				if (source.modifiers.contains(mod)) {
					addError('''DataPoints cannot be «mod»''')
				}
			}
			makeStatic
			visibility = Visibility.PUBLIC
		]
		if (!theories.isEmpty && cls.findAnnotation(RunWith.findTypeGlobally) == null) {
			cls.importAssume
			cls.addAnnotation(
				RunWith.newAnnotationReference [
					setClassValue("value", Theories.newTypeReference)
				])
		}
		validateLater[
			dataPointsMembers.forEach[
				if (!type.isArray) {
					//TODO in 4.12, @DataPoints can be Iterables
					addError("DataPoints must return an array")
				}
			]
			
			//TODO in 4.12, this became much more sophisticated
			val dataPointTypes = newHashSet
			dataPointTypes += dataPointMembers.map[type]
			dataPointTypes += dataPointsMembers.map[componentType]
			theories.forEach [
				parameters.forEach [
					if (!dataPointTypes.contains(type)) {
						addError('''No @DataPoints of type «type.simpleName» specified''')
					}
				]
			]
		]
	}

	def importAssert(MutableClassDeclaration cls) {
		Assert.newTypeReference.declaredResolvedMethods.filter [
			declaration.visibility == Visibility.PUBLIC && 
			declaration.deprecated == false
		].forEach [ m |
			cls.addMethod(m.declaration.simpleName) [
				copySignatureFrom(m)
				visibility = Visibility.PRIVATE
				primarySourceElement = cls
				body = '''
					«Assert».«typeParameters.join("<", ",", ">")[simpleName]»«simpleName»(«parameters.join(", ")[simpleName]»);
				'''
			]
		]
	}

	def importAssume(MutableClassDeclaration cls) {
		Assume.newTypeReference.declaredResolvedMethods.filter [
			declaration.visibility == Visibility.PUBLIC && 
			declaration.deprecated == false
		].forEach [ m |
			cls.addMethod(m.declaration.simpleName) [
				copySignatureFrom(m)
				visibility = Visibility.PRIVATE
				primarySourceElement = cls
				body = '''
					«Assume».«typeParameters.join("<", ",", ">")[simpleName]»«simpleName»(«parameters.join(", ")[simpleName]»);
				'''
			]
		]
	}

	def importJUnitExtensions(MutableClassDeclaration cls) {
		cls.addMethod("operator_doubleArrow") [
			visibility = Visibility.PRIVATE
			static = true
			val t = addTypeParameter("T", object).newTypeReference
			val u = addTypeParameter("U", t).newTypeReference
			addParameter("actual", t)
			addParameter("expected", u)
			primarySourceElement = cls
			body = '''
				«Assert».assertEquals(expected, actual);
			'''
		]
		cls.addMethod("isThrownBy") [
			visibility = Visibility.PRIVATE
			static = true
			val t = addTypeParameter("T", Exception.newTypeReference).newTypeReference
			addParameter("expected", Class.newTypeReference(t))
			addParameter("block", Procedures.Procedure0.newTypeReference)
			primarySourceElement = cls
			body = '''
				try {
					block.apply();
					«Assert».fail("Expected a " + expected.getName());
				} catch (Exception e) {
					Class<?> actual = e.getClass();
					«Assert».assertTrue(
						"Expected a " + expected.getName() + " but got " + actual.getName(), 
						expected.isAssignableFrom(actual)
					);
				}
			'''
		]
	}

	def dispatch makeStatic(MutableFieldDeclaration member) {
		member.static = true
	}

	def dispatch makeStatic(MutableMethodDeclaration member) {
		member.static = true
	}

	def getComponentType(MutableMemberDeclaration member) {
		val type = member.type
		if (type.isArray) {
			return type.arrayComponentType
		} else if (type.actualTypeArguments.size == 1) {
			return type.actualTypeArguments.head
		} else {
			return object
		}
	}

	def dispatch getType(MutableFieldDeclaration member) {
		member.type
	}

	def dispatch getType(MutableMethodDeclaration member) {
		member.returnType
	}
}
