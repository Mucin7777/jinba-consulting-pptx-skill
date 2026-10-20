"""スキルの入口とセットアップ用ファイルの自己テスト。

  python3 -m unittest discover -s tests
"""
import re
import shutil
import subprocess
import unittest
import xml.dom.minidom
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def frontmatter(path):
    return re.match(r"---\n.*?\n---\n", path.read_text(encoding="utf8"), re.S).group(0)


class SkillEntry(unittest.TestCase):
    def test_entry_matches_root_skill(self):
        # セッションに入れたリポジトリから読まれる入口は、直下の SKILL.md と同じ名前・説明で発火させる
        entry = ROOT / ".claude" / "skills" / "consulting-pptx-skill" / "SKILL.md"
        self.assertEqual(frontmatter(entry), frontmatter(ROOT / "SKILL.md"),
                         "SKILL.md の frontmatter を変えたら .claude/skills/consulting-pptx-skill/SKILL.md も揃える")


class LinuxSetup(unittest.TestCase):
    def test_fontconfig_is_well_formed(self):
        # XML として壊れていると fontconfig は黙って無視する（コメントの中の "--" でも壊れる）
        xml.dom.minidom.parse(str(ROOT / "scripts" / "fontconfig-ja.conf"))

    @unittest.skipUnless(shutil.which("bash"), "bash が要る")
    def test_setup_script_parses(self):
        r = subprocess.run(["bash", "-n", str(ROOT / "scripts" / "setup_linux.sh")], capture_output=True, text=True)
        self.assertEqual(r.returncode, 0, r.stderr)


if __name__ == "__main__":
    unittest.main()
