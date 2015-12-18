xtend-junit
===========

This project shows how [Xtend](https://xtend-lang.org)'s Active Annotations can be used to enhance tooling for a specific framework. It solves most of the things that I did not like about Junit 4. Most of these issues will be fixed in the new Junit Lambda project, so I won't put much more work into this one.

See the [examples](https://github.com/oehme/xtend-junit/tree/master/xtend-junit-examples/src/test/java) or read on for more details.

```groovy
testCompile 'com.github.oehme.xtend:xtend-junit:$version'
```

[![Build Status](https://travis-ci.org/oehme/xtend-junit.svg)](https://travis-ci.org/oehme/xtend-junit)
[![Download](https://api.bintray.com/packages/oehme/maven/xtend-junit/images/download.svg) ](https://bintray.com/oehme/maven/xtend-junit/_latestVersion)

@Junit
------

This annotation automates common JUnit patterns. It also adds compile-time validation and convenience methods for more readable tests.

- a method is automatically annotated with ```@Test``` if it is
  - public
  - non-static
  - not annotated with ```@Theory``` or ```@DataPoint```
- Test methods are automatically ```void```
- a compile error is raised if a test method declares parameters
- ```org.junit.Assert.*``` is statically imported
- you can use ```x => 3``` instead of ```assertEquals(3, x)```
- expected exceptions can be declared using a lambda expression like ```IllegalArgumentException.isThrownBy[Integer.parseInt("Foo")]```
- fields annotated with ```@Rule``` are automatically public
- a compile error is raised if a ```@Rule``` has any other visibility or is declared static
- fields/methods annotated with ```@DataPoint``` are automatically public und static
- if a test is annotated with ```@Theory```, the test class will get the ```@RunWith(Theories)``` annotation
- if there are ```@Theory```(s), ```org.junit.Assume.*``` is statically imported
- ```@Theory``` parameters are flagged with an error if there are not matching ```@DataPoint```s

@Hamcrest
---------

- you can use ```"Foo" => startsWith("F")```instead of ```assertThat("Foo", startsWith("F"))```
- ```org.hamcrest.CoreMatchers``` or ```org.hamcrest.Matchers``` is statically imported, depending on which is on the classpath
- an ErrorCollector is added as an extension field, so you can softly assert using ```checkThat(expected, Matcher)```)

@AutoSuite
----------

Collects all tests in a package (and optionally all subpackages) and creates a Suite from them. Especially useful if you want to group your tests using Categories instead of writing @SuiteClasses manually. This is basically like using [ClassPathSuite](http://www.johanneslink.net/projects/cpsuite.jsp), but statically generated, so you will have quick test startup times.
