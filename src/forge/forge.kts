import net.minecraftforge.installer.SimpleInstaller
import net.minecraftforge.installer.actions.Actions
import net.minecraftforge.installer.actions.ProgressCallback
import net.minecraftforge.installer.json.Util
import net.minecraftforge.installer.DownloadUtils
import java.io.File

SimpleInstaller.headless = true
DownloadUtils.OFFLINE_MODE = true

val installer = File(
    SimpleInstaller::class.java
        .getProtectionDomain()
        .getCodeSource()
        .getLocation()
        .toURI()
)
Actions.CLIENT
    .getAction(Util.loadInstallProfile(), ProgressCallback.TO_STD_OUT)
    .run(File("."), { true }, installer)
