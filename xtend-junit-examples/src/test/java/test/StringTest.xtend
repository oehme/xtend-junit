package test

import de.oehme.xtend.junit.Hamcrest
import de.oehme.xtend.junit.JUnit

@JUnit @Hamcrest
class StringTest {
	def factsAboutMyName() {
		"Stefan" => startsWith("S")
		"Stefan" => containsString("fan")
		"Stefan".length => greaterThan(5)
	}
}