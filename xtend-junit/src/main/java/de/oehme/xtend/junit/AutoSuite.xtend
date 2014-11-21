package de.oehme.xtend.junit

import java.util.regex.Pattern
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
	
	def Iterable<Type> findTypes(extension TransformationContext context, Path packageFolder, boolean includeSubPackages) {
		val currentPackage = packageFolder.sourceFolder.relativize(packageFolder).toString.replace("/",".")
		val packagePrefix = if (currentPackage.isEmpty) "" else currentPackage + "."
		val types = newArrayList
		types += packageFolder.children
			.filter[fileExtension == "xtend" || fileExtension == "java"]
			.map[containedTypes(context)].flatten
			.map[findTypeGlobally(packagePrefix + it)]
			.filterNull
		if (includeSubPackages) {
			types += packageFolder.children.filter[isFolder].map[context.findTypes(it, includeSubPackages)].flatten
		}
		types
	}
	
	
	static val TYPE_PATTERN = Pattern.compile(".*(class|interface|enum|annotation)\\s+([^\\s{]+).*")
	
	//TODO this approach breaks for nested classes and commented code
	def containedTypes(Path file, extension TransformationContext context) {
		val matcher = TYPE_PATTERN.matcher(file.contents)
		val typeNames = newArrayList
		while (matcher.find) {
			typeNames += matcher.group(2)
		}
		typeNames
	}
}
