package de.oehme.xtend.junit

import de.oehme.xtend.contrib.Reflections
import org.eclipse.xtend.lib.macro.AbstractClassProcessor
import org.eclipse.xtend.lib.macro.Active
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.declaration.ClassDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableClassDeclaration
import org.junit.Test
import org.junit.runner.RunWith
import org.junit.runners.Suite
import org.junit.runners.Suite.SuiteClasses

@Active(AutoSuiteProcessor)
annotation AutoSuite {
	boolean includeSubPackages = false
}

class AutoSuiteProcessor extends AbstractClassProcessor {

	override doTransform(MutableClassDeclaration cls, extension TransformationContext context) {
		val extension reflections = new Reflections(context)
		if (cls.findAnnotation(RunWith.findTypeGlobally) == null) {
			cls.addAnnotation(
				RunWith.newAnnotationReference [
					setClassValue("value", Suite.newTypeReference)
				])
		}
		val packageFolder = cls.compilationUnit.filePath.parent
		val suiteAnnotation = cls.findAnnotation(AutoSuite.findTypeGlobally)
		val testTypes = packageFolder.findTypes(suiteAnnotation.getBooleanValue("includeSubPackages"))
		.filter(ClassDeclaration)
		.filter[
			findAnnotation(JUnit.findTypeGlobally) !== null
			|| newTypeReference.allResolvedMethods.exists[declaration.findAnnotation(Test.findTypeGlobally) !== null]
		]
		.map[newTypeReference]
		cls.addAnnotation(
			SuiteClasses.newAnnotationReference [
				setClassValue("value", testTypes)
			])
	}
}
