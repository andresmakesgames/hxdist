package targets;

import haxe.io.Path;

class HashLinkC extends Target {
    public function new(dd:String, pd: String, pn:String) {
        super(dd, pd, pn);
    }

	var sourceFile = '';
	var sourceDir = '';

    public override function compile(hxml:String, outputDir:String) {
		Term.print("Generating HL/C source code...");

        if(Sys.command("haxe", [hxml]) != 0)
			Term.error('Compilation failed!');

        var hxmlContent = Target.parseHxml(projDir, hxml);

		for(line in hxmlContent) {
			if(line.indexOf('-hl ') >= 0) {
				sourceFile = line.split('-hl ')[1];
				sourceDir = Path.directory(sourceFile);
				Term.print('Found source file: $sourceFile');
			}
		}

		var cwd = Sys.getCwd();

		if(Sys.systemName() == 'Linux') {
			Term.print("Attempting Linux build with gcc... ");
			createPackageGcc(hxmlContent, outputDir + '/hlc_linux', linuxFiles);

			// Term.print("Attempting windows build with MinGW-w64...");
			// createPackageMinGW(hxmlContent, outputDir + '/hlc_win', winFiles);
		}
		else if(Sys.systemName() == 'Windows') {
			// Term.warning("Windows HL/C build not yet implemented...");
			Term.print("Attempting Windows build with gcc... ");
			// createPackageMSVC(hxmlContent, outputDir + '/hlc_win', winFiles);
			createPackageGcc(hxmlContent, outputDir + '/hlc_win', winFiles);
		}
		else if(Sys.systemName() == 'Mac') {
			createPackageGcc(hxmlContent, outputDir + '/hlc_mac', macFiles);
		}
		else {
			Term.error("Could not determine current system...");
		}
	}

    function createPackageGcc(hxml:Array<String>, packageDir:String, files:Target.RuntimeFiles) {
		Term.print("Packaging " + packageDir + "...");
		FileUtil.createDirectory(packageDir);

		var result = 0;
		if(Sys.systemName() == 'Mac') {
			var customHashlinkDir = "../hashlink/src";
			result = runCommand('gcc', [
				sourceFile,
				'-arch arm64',
				'-O3',
				'-o $packageDir/$projName',
				'-I $sourceDir',
				'-I $customHashlinkDir',
				'-lhl /usr/local/lib/*.hdll',
				'-L /opt/homebrew/opt/libuv/lib',
				'-luv',
				'-lm',
				'-w'
			]);
		}
		else {
			result = runCommand('gcc', [
				'$sourceFile',
				'-o',
				'$packageDir/$projName',
				'-w',
				'-std=c11',
				'-I$sourceDir',
				'-lhl /usr/local/lib/*.hdll',
				'-lm',
				'-lGL'
			]);
		}
		
		if(result == 0) {
			// Runtimes
			copyRuntimeFiles(hxml, packageDir, files);
			Term.print('gcc build successfull!');
		} else {
			Term.error('gcc build failed. Error code: $result');
		}
	}

	function createPackageMinGW(hxml:Array<String>, packageDir:String, files:Target.RuntimeFiles) {
		Term.print("Packaging " + packageDir + "...");
		FileUtil.createDirectory(packageDir);

		var result = runCommand('x86_64-w64-mingw32-gcc', [
			'$sourceFile',
			'-o',
			'$packageDir/$projName',
			// '-w',
			'-std=c11',
			'-I$sourceDir',
			'-lhl /usr/local/lib/*.hdll',
			'-lm',
			'-lGL'
		]);

		if(result == 0) {
			Term.print('Windows build finished.');
		} else {
			Term.print('Windows build failed.');
		}

		// Runtimes
		copyRuntimeFiles(hxml, packageDir, files);
	}

	function createPackageMSVC(hxml:Array<String>, packageDir:String, files:Target.RuntimeFiles) {
		Term.print("Packaging " + packageDir + "...");
		FileUtil.createDirectory(packageDir);

		// cl.exe /FeNecrovale.exe -I "C:\HaxeToolkit\hl\include" -I "bin/tmp" "bin/tmp/client.c" "C:\HaxeToolkit\hl\*.lib"
		var result = runCommand('cl.exe', [
			'$sourceFile',
			'/Fe$packageDir/$projName.exe',
			'-I"C:/HaxeToolkit/hl/include"',
			'-I"$sourceDir"',
			'$sourceFile',
			'"C:/HaxeToolkit/hl/*.lib"',
		]);

		if(result == 0) {
			Term.print('Windows build finished.');
		} else {
			Term.print('Windows build failed.');
		}

		// Runtimes
		copyRuntimeFiles(hxml, packageDir, files);
	}

    var winFiles : Target.RuntimeFiles = {
		platform: Windows,
        dir: 'dist_files/hl_win/',
		files: [
			// common
			{ f:"fmt.hdll" },
			{ f:"ssl.hdll" },
			{ f:"mysql.hdll" },
			{ f:"hlimgui.hdll", lib:"hlimgui" },
			{ f:"sdl.hdll", lib:"hlsdl" },
			{ f:"directx.hdll", lib:"hldx" },
			{ f:"steam.hdll", lib:"hlsteam" },
			{ f:"openal.hdll", lib:"heaps" },
			{ f:"ui.hdll", lib:"heaps" },
			{ f:"uv.hdll", lib:"heaps" },

			{ f:"libhl.dll" },
			{ f:"msvcr120.dll" },
			{ f:"msvcp120.dll" },
			{ f:"libmbedcrypto.dll" },
			{ f:"libmbedtls.dll" },
			{ f:"libmbedx509.dll" },
			{ f:"libpcre-1.dll" },
			{ f:"zlib1.dll" },
			{ f:"OpenAL32.dll", lib:"heaps" },
			{ f:"SDL2.dll", lib:"hlsdl" },
			{ f:"steam_api64.dll", lib:"hlsteam" },
		],
	}

	var macFiles: Target.RuntimeFiles = {
		platform: Mac,
        dir: 'dist_files/hl_mac/',
		files: [
			{ f:"libhl.dylib" },
			{ f:"mysql.hdll" },

			{ f:"fmt.hdll" },
			{ f:"libpng16.16.dylib" },
			{ f:"libvorbis.0.dylib" },
			{ f:"libvorbisfile.3.dylib" },

			{ f:"ssl.hdll" },
			{ f:"libmbedtls.14.dylib" },

			{ f:"sdl.hdll", lib:"hlsdl" },
			{ f:"libSDL2-2.0.0.dylib", lib:"hlsdl" },
			
			{ f:"ui.hdll", lib:"heaps" },
			{ f:"uv.hdll", lib:"heaps" },
			{ f:"openal.hdll", lib:"heaps" },
			{ f:"libuv.1.dylib", lib:"heaps" },
			{ f:"libopenal.1.dylib", lib:"heaps" },

			{ f:"steam.hdll", lib:"hlsteam" },
		],
	}

	var linuxFiles: Target.RuntimeFiles = {
		platform: Linux,
        dir: 'dist_files/hl_linux/',
		files: [
			{ f:"libhl.so" },
			{ f:"mysql.hdll" },

			{ f:"ssl.hdll" },
			{ f:"libmbedtls.so.10" },
			{ f:"libmbedx509.so.0" },
			{ f:"libmbedcrypto.so.0" },

			// FMT
			{ lib:"heaps", f:"fmt.hdll" },
			{ lib:"heaps", f:"libpng16.so.16" },
			{ lib:"heaps", f:"libturbojpeg.so.0" }, 
			{ lib:"heaps", f:"libvorbisfile.so.3" },
			{ lib:"heaps", f:"libvorbis.so.0" },
			{ lib:"heaps", f:"libogg.so.0" },

			// openAL
			{ lib:"heaps", f:"openal.hdll" },
			{ lib:"heaps", f:"libopenal.so.1" },

			// UI
			{ lib:"heaps", f:"ui.hdll" },

			// UV
			{ lib:"heaps", f:"uv.hdll" },
			{ lib:"heaps", f:"libuv.so.1" },

			// SDL
			{ lib:"hlsdl", f:"sdl.hdll" },
			{ lib:"hlsdl", f:"libSDL2-2.0.so.0" },
			{ lib:"hlsdl", f:"libsndio.so.6.1" },

			// Steam
			{ lib:"hlsteam", f:"steam.hdll" },
            { lib:"hlsteam", f:"libsteam_api.so" },
		],
	}
}