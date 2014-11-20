package test 

import de.oehme.xtend.junit.JUnit
import org.junit.experimental.theories.DataPoints
import org.junit.experimental.theories.Theory

@JUnit
class IntegerTest {
	@DataPoints val int[] ints = #[-2, -1, 0, 1, 2]

	@Theory
	def additionIsCommutative(int a, int b) {
		a + b => b + a
	}
}
