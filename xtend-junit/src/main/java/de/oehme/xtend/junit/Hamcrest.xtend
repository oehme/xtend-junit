package de.oehme.xtend.junit

import de.oehme.xtend.contrib.SignatureHelper
import org.eclipse.xtend.lib.macro.AbstractClassProcessor
import org.eclipse.xtend.lib.macro.Active
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.declaration.MutableClassDeclaration
import org.eclipse.xtend.lib.macro.declaration.Visibility
import org.hamcrest.Matcher
import org.junit.Assert
import org.junit.rules.ErrorCollector
import org.junit.Rule

@Active(HamcrestProcessor)
annotation Hamcrest {
}

class HamcrestProcessor extends AbstractClassProcessor {

	override doTransform(MutableClassDeclaration cls, extension TransformationContext context) {
		val extension SignatureHelper = new SignatureHelper(context)
		cls.addField("_errorCollector")[
			type = ErrorCollector.newTypeReference
			visibility = Visibility.PUBLIC
			final = true
			addAnnotation(Rule.newAnnotationReference)
			addAnnotation(Extension.newAnnotationReference)
			primarySourceElement = cls
			initializer = '''new «ErrorCollector»()'''
		]
		/*
		 * TODO as soon as the active annotation API
		 * supports adding static/extension imports,
		 * these can be moved to a small library/just imported
		 */
		cls.addMethod("operator_doubleArrow") [
			visibility = Visibility.PRIVATE
			val t = addTypeParameter("T", object).newTypeReference
			addParameter("object", t)
			addParameter("matcher", Matcher.newTypeReference(t.newWildcardTypeReferenceWithLowerBound))
			primarySourceElement = cls
			body = '''
				«Assert».assertThat(object, matcher);
			'''
		]
		
		val matchers = findTypeGlobally("org.hamcrest.Matchers")?: findTypeGlobally("org.hamcrest.CoreMatchers")
		matchers.newTypeReference.declaredResolvedMethods
		.filter[
			declaration.visibility == Visibility.PUBLIC &&
			declaration.deprecated == false
		]
		.forEach[m|
			cls.addMethod(m.declaration.simpleName) [
				copySignatureFrom(m)
				visibility = Visibility.PRIVATE
				primarySourceElement = cls
				body = '''
					return «matchers».«typeParameters.join("<", ",", ">")[simpleName]»«simpleName»(«parameters.join(", ")[simpleName]»);
				'''
			]
		]
	}

}
 