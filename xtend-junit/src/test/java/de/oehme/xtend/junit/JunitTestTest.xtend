package de.oehme.xtend.junit

import com.google.common.collect.Iterables
import org.eclipse.xtend.core.compiler.batch.XtendCompilerTester
import org.hamcrest.Matcher
import org.junit.Assert
import org.junit.Test
import org.junit.runner.JUnitCore
import org.junit.runners.model.MultipleFailureException

class JunitTestTest {
	extension XtendCompilerTester = XtendCompilerTester::newXtendCompilerTester(
		JUnit,
		Iterables,
		Exceptions,
		Assert,
		Matcher
	)

	@Test
	def void test() {
		'''
			import de.oehme.xtend.junit.JUnit
			@JUnit
			class SampleTest {
				def simple() {
					1 => 1
				}
			}		
		'''.compile [
			compiledClass.run
		]
	}

	private def run(Class<?> test) {
		val result = JUnitCore.runClasses(test)
		val failures = result.failures
		if (!failures.isEmpty) {
			throw new MultipleFailureException(failures.map[exception])
		}
	}
}
