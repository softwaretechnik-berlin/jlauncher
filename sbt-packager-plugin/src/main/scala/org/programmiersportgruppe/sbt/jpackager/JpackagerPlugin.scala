package org.programmiersportgruppe.sbt.jpackager

import org.json4s._
import org.json4s.native.JsonMethods._

import java.io.{FileOutputStream, OutputStreamWriter}

import sbt.{Artifact, Attributed, ModuleID, _}
import sbt.Keys._
import sbt.plugins.JvmPlugin

object JpackagerPlugin extends AutoPlugin {

  override def trigger = allRequirements

  override def requires = JvmPlugin

  object autoImport {
    // Perhaps this should not be inmported automatically
    val generateManifest: TaskKey[Seq[sbt.File]] = taskKey[Seq[File]]("A task to generate an application manifest")
  }

  import autoImport._

  override lazy val projectSettings = Seq(

    generateManifest := Def.task {

      val classpath: Seq[Attributed[File]] = Classpaths.managedJars(Compile, classpathTypes.value, update.value)
      val logger = sLog.value

      val repos: Seq[String] = (fullResolvers in Compile).value.collect{case r: MavenRepo => r.root}
      val deps: Seq[(Artifact, ModuleID)] = classpath.flatMap { entry =>
        for {
          art: Artifact <- entry.get(artifact.key)
          mod: ModuleID <- entry.get(moduleID.key)
        } yield {
          logger.debug(
            s"""[Lock] "${mod.organization}" % "${mod.name}" % "${mod.revision}""""
          )
          (art, mod, entry.data)
        }
      }
      val targetPath = (resourceManaged in Compile).value
      generateManifest(targetPath, deps, repos, mainClass.value.getOrElse(""))
    }.value

  )

  override lazy val buildSettings = Seq()

  override lazy val globalSettings = Seq()

  def generateManifest(base: File, deps: Seq[(Artifact, ModuleID)], repos: Seq[String], mainClassName: String): Seq[File] = {

    val path = new File(base, "j-manifest.json")
    base.mkdirs()
    val writer = new OutputStreamWriter(new FileOutputStream(path), "UTF-8")

    val root = JObject(
      "mainClass" -> JString(mainClassName),
      "dependencies" -> JArray(deps.map(dep => {
        val moduleID = dep._2
        val artifact = dep._1
        JObject(
          "groupId" -> JString(moduleID.organization),
          "artifactId" -> JString(moduleID.name),
          "version" -> JString(moduleID.revision),
          "size" -> JString(artifact.url.map(u => u.toString).getOrElse("-")),
          "configurations" -> JString(moduleID.configurations.getOrElse(null))
        )
      }
      ).toList),
      "repositories" -> JArray(repos.map(r => JString(r)).toList)
    )

    writer.write(pretty(render(root)))
    writer.close()
    Seq(path)
  }
}