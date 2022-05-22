package net.minecraftforge.installertools;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.io.IOException;

public class DownloadMojmaps extends Task {
    @Override
    public void process(String[] args) throws IOException {
        String outputFile = args[java.util.Arrays.asList(args).indexOf("--output") + 1];
        System.err.println("Moving mappings.txt to " + outputFile);
        Files.move(Paths.get("mappings.txt"), Paths.get(outputFile));
    }
}
