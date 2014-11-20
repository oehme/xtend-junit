package de.oehme.xtend.junit

import org.eclipse.xtend.lib.macro.AbstractClassProcessor
import org.eclipse.xtend.lib.macro.Active
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.declaration.ClassDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableClassDeclaration
import org.eclipse.xtend.lib.macro.declaration.Type
import org.eclipse.xtend.lib.macro.file.Path
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
		if (cls.findAnnotation(RunWith.findTypeGlobally) == null) {
			cls.addAnnotation(
				RunWith.newAnnotationReference [
					setClassValue("value", Suite.newTypeReference)
				])
		}
		val packageFolder = cls.compilationUnit.filePath.parent
		val suiteAnnotation = cls.findAnnotation(AutoSuite.findTypeGlobally)
		val testTypes = context.findTypes(packageFolder, suiteAnnotation.getBooleanValue("includeSubPackages"))
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
	
	//TODO use regex to find actual type names inside the file
	def Iterable<Type> findTypes(extension TransformationContext context, Path packageFolder, boolean includeSubPackages) {
		val currentPackage = packageFolder.sourceFolder.relativize(packageFolder).toString.replace("/",".")
		val packagePrefix = if (currentPackage.isEmpty) "" else currentPackage + "."
		val types = newArrayList
		types += packageFolder.children
			.filter[fileExtension == "xtend" || fileExtension == "java"]
			.map[findTypeGlobally(packagePrefix + lastSegment.split("\\.").get(0))]
			.filterNull
		if (includeSubPackages) {
			types += packageFolder.children.filter[isFolder].map[context.findTypes(it, includeSubPackages)].flatten
		}
		types
	}
}
