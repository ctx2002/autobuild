<?php

$submodules = file(".gitmodules");
$paths = [];
$modules = [];
foreach ($submodules as $value) {
	$str = trim($value);
	if (preg_match("%^path(.*)%ism",$str, $m)) {
		$paths[] = trim( ltrim( trim($m[1]),'='));
	} else if (preg_match("%^url(.*)%ism",$str, $m)) {
		$modules[] = trim( ltrim( trim($m[1]),'='));
	}
}


$itp = new ArrayIterator($paths);
$itm = new ArrayIterator($modules);

$it = new \MultipleIterator(MultipleIterator::MIT_NEED_ALL|MultipleIterator::MIT_KEYS_ASSOC);
$it->attachIterator($itp, 'path');
$it->attachIterator($itm, 'sub');

foreach ($it as $value) {
	$cmd = "git submodule add -f " . $value['sub'] . " " . $value['path'];
    shell_exec($cmd);
}

$cmd = 'git submodule update --init --recursive';
shell_exec($cmd);