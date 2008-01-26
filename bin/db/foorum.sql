-- phpMyAdmin SQL Dump
-- version 2.11.1-rc1
-- http://www.phpmyadmin.net
--
-- Host: localhost
-- Generation Time: Dec 27, 2007 at 11:15 AM
-- Server version: 6.0.3
-- PHP Version: 5.2.5

SET SQL_MODE="NO_AUTO_VALUE_ON_ZERO";

--
-- Database: `foorum`
--

-- --------------------------------------------------------

--
-- Table structure for table `banned_ip`
--

CREATE TABLE IF NOT EXISTS `banned_ip` (
  `ip_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `cidr_ip` varchar(20) NOT NULL DEFAULT '',
  `time` int(11) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`ip_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `comment`
--

CREATE TABLE IF NOT EXISTS `comment` (
  `comment_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `reply_to` int(11) unsigned NOT NULL DEFAULT '0',
  `text` text NOT NULL,
  `post_on` datetime DEFAULT NULL,
  `update_on` datetime DEFAULT NULL,
  `post_ip` varchar(32) NOT NULL DEFAULT '',
  `formatter` varchar(16) NOT NULL DEFAULT 'ubb',
  `object_type` varchar(30) NOT NULL,
  `object_id` int(11) unsigned NOT NULL DEFAULT '0',
  `author_id` int(11) unsigned NOT NULL DEFAULT '0',
  `title` varchar(255) NOT NULL DEFAULT '',
  `forum_id` int(11) unsigned NOT NULL DEFAULT '0',
  `upload_id` int(11) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`comment_id`),
  KEY `comment_id` (`comment_id`),
  KEY `upload_id` (`upload_id`),
  KEY `author_id` (`author_id`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `filter_word`
--

CREATE TABLE IF NOT EXISTS `filter_word` (
  `word` varchar(64) NOT NULL,
  `type` enum('username_reserved','forum_code_reserved','bad_email_domain','offensive_word','bad_word') NOT NULL DEFAULT 'username_reserved',
  PRIMARY KEY (`word`,`type`),
  KEY `word` (`word`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `forum`
--

CREATE TABLE IF NOT EXISTS `forum` (
  `forum_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `forum_code` varchar(25) NOT NULL,
  `name` varchar(100) NOT NULL,
  `description` varchar(255) NOT NULL,
  `forum_type` varchar(16) NOT NULL,
  `policy` enum('public','private','protected') NOT NULL DEFAULT 'public',
  `total_members` int(8) NOT NULL DEFAULT '0',
  `total_topics` int(11) NOT NULL DEFAULT '0',
  `total_replies` int(11) NOT NULL DEFAULT '0',
  `status` enum('healthy','banned','deleted') NOT NULL DEFAULT 'healthy',
  `last_post_id` int(11) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`forum_id`),
  UNIQUE KEY `forum_code` (`forum_code`),
  KEY `forum_id` (`forum_id`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8;


CREATE TABLE `forum_settings` (
  `forum_id` int(11) unsigned NOT NULL DEFAULT '0',
  `type` varchar(48) NOT NULL,
  `value` varchar(48) NOT NULL,
  PRIMARY KEY (`forum_id`,`type`),
  KEY `forum_id` (`forum_id`)
);

-- --------------------------------------------------------

--
-- Table structure for table `hit`
--

CREATE TABLE IF NOT EXISTS `hit` (
  `hit_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `object_type` varchar(12) NOT NULL,
  `object_id` int(11) unsigned NOT NULL DEFAULT '0',
  `hit_new` int(11) unsigned NOT NULL DEFAULT '0',
  `hit_today` int(11) unsigned NOT NULL DEFAULT '0',
  `hit_yesterday` int(11) unsigned NOT NULL DEFAULT '0',
  `hit_weekly` int(11) unsigned NOT NULL DEFAULT '0',
  `hit_monthly` int(11) unsigned NOT NULL DEFAULT '0',
  `hit_all` int(11) unsigned NOT NULL DEFAULT '0',
  `last_update_time` int(11) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`hit_id`),
  KEY `object` (`object_type`,`object_id`),
  KEY `object_type` (`object_type`),
  KEY `last_update_time` (`last_update_time`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `log_action`
--

CREATE TABLE IF NOT EXISTS `log_action` (
  `user_id` int(11) unsigned NOT NULL DEFAULT '0',
  `action` varchar(24) DEFAULT NULL,
  `object_type` varchar(12) DEFAULT NULL,
  `object_id` int(11) DEFAULT NULL,
  `time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `text` text,
  `forum_id` int(11) unsigned NOT NULL DEFAULT '0',
  KEY `user_id` (`user_id`),
  KEY `forum_id` (`forum_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `log_error`
--

CREATE TABLE IF NOT EXISTS `log_error` (
  `error_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `level` enum('info','debug','warn','error','fatal') NOT NULL DEFAULT 'debug',
  `text` text NOT NULL,
  `time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`error_id`),
  KEY `level` (`level`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `log_path`
--

CREATE TABLE IF NOT EXISTS `log_path` (
  `path_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `session_id` varchar(72) DEFAULT NULL,
  `user_id` int(11) unsigned NOT NULL DEFAULT '0',
  `path` varchar(255) NOT NULL DEFAULT '',
  `get` varchar(255) DEFAULT NULL,
  `post` text,
  `time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `loadtime` double NOT NULL DEFAULT '0',
  PRIMARY KEY (`path_id`),
  KEY `path` (`path`),
  KEY `session_id` (`session_id`),
  KEY `user_id` (`user_id`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `message`
--

CREATE TABLE IF NOT EXISTS `message` (
  `message_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `from_id` int(11) unsigned NOT NULL DEFAULT '0',
  `to_id` int(11) unsigned NOT NULL DEFAULT '0',
  `title` varchar(255) NOT NULL,
  `text` text NOT NULL,
  `post_on` datetime NOT NULL,
  `post_ip` varchar(32) NOT NULL DEFAULT '',
  `from_status` enum('open','deleted') NOT NULL DEFAULT 'open',
  `to_status` enum('open','deleted') NOT NULL DEFAULT 'open',
  PRIMARY KEY (`message_id`),
  KEY `message_id` (`message_id`),
  KEY `to_id` (`to_id`),
  KEY `from_id` (`from_id`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `message_unread`
--

CREATE TABLE IF NOT EXISTS `message_unread` (
  `message_id` int(11) unsigned NOT NULL DEFAULT '0',
  `user_id` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`message_id`,`user_id`),
  KEY `message_id` (`message_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `poll`
--

CREATE TABLE IF NOT EXISTS `poll` (
  `poll_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `forum_id` int(11) unsigned NOT NULL DEFAULT '0',
  `author_id` int(11) unsigned NOT NULL DEFAULT '0',
  `multi` enum('0','1') NOT NULL DEFAULT '0',
  `anonymous` enum('0','1') NOT NULL DEFAULT '0',
  `time` int(10) DEFAULT NULL,
  `duration` int(10) DEFAULT NULL,
  `vote_no` mediumint(8) unsigned NOT NULL DEFAULT '0',
  `title` varchar(128) DEFAULT NULL,
  `hit` int(11) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`poll_id`),
  KEY `poll_id` (`poll_id`),
  KEY `author_id` (`author_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `poll_option`
--

CREATE TABLE IF NOT EXISTS `poll_option` (
  `option_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `poll_id` int(11) unsigned NOT NULL DEFAULT '0',
  `text` varchar(255) DEFAULT NULL,
  `vote_no` mediumint(8) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`option_id`),
  KEY `option_id` (`option_id`),
  KEY `poll_id` (`poll_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `poll_result`
--

CREATE TABLE IF NOT EXISTS `poll_result` (
  `option_id` int(11) unsigned NOT NULL DEFAULT '0',
  `poll_id` int(11) unsigned NOT NULL DEFAULT '0',
  `poster_id` int(11) unsigned NOT NULL DEFAULT '0',
  `poster_ip` varchar(32) DEFAULT NULL,
  KEY `poll_id` (`poll_id`),
  KEY `option_id` (`option_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `scheduled_email`
--

CREATE TABLE IF NOT EXISTS `scheduled_email` (
  `email_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `email_type` varchar(24) DEFAULT NULL,
  `processed` enum('Y','N') NOT NULL DEFAULT 'N',
  `from_email` varchar(128) DEFAULT NULL,
  `to_email` varchar(128) DEFAULT NULL,
  `subject` text,
  `plain_body` text,
  `html_body` text,
  `time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`email_id`),
  KEY `processed` (`processed`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `session`
--

CREATE TABLE IF NOT EXISTS `session` (
  `id` char(72) NOT NULL DEFAULT '',
  `session_data` text,
  `expires` int(11) DEFAULT '0',
  `user_id` int(11) unsigned NOT NULL DEFAULT '0',
  `path` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `share`
--

CREATE TABLE IF NOT EXISTS `share` (
  `user_id` int(11) unsigned NOT NULL DEFAULT '0',
  `object_type` varchar(12) NOT NULL DEFAULT '',
  `object_id` int(11) unsigned NOT NULL DEFAULT '0',
  `time` int(10) NOT NULL DEFAULT '0',
  PRIMARY KEY (`user_id`,`object_id`,`object_type`),
  KEY `user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `star`
--

CREATE TABLE IF NOT EXISTS `star` (
  `user_id` int(11) unsigned NOT NULL DEFAULT '0',
  `object_type` varchar(12) NOT NULL DEFAULT '',
  `object_id` int(11) unsigned NOT NULL DEFAULT '0',
  `time` int(10) NOT NULL DEFAULT '0',
  PRIMARY KEY (`user_id`,`object_id`,`object_type`),
  KEY `user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `stat`
--

CREATE TABLE IF NOT EXISTS `stat` (
  `stat_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `stat_key` varchar(255) NOT NULL,
  `stat_value` bigint(21) NOT NULL DEFAULT '0',
  `date` date NOT NULL,
  PRIMARY KEY (`stat_id`),
  KEY `key` (`stat_key`),
  KEY `date` (`date`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `topic`
--

CREATE TABLE IF NOT EXISTS `topic` (
  `topic_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `forum_id` int(11) unsigned NOT NULL DEFAULT '0',
  `title` varchar(255) DEFAULT NULL,
  `closed` enum('0','1') NOT NULL DEFAULT '0',
  `sticky` enum('0','1') NOT NULL DEFAULT '0',
  `elite` enum('0','1') NOT NULL DEFAULT '0',
  `hit` int(11) NOT NULL DEFAULT '0',
  `last_updator_id` int(11) unsigned NOT NULL DEFAULT '0',
  `last_update_date` datetime DEFAULT NULL,
  `author_id` int(11) unsigned NOT NULL DEFAULT '0',
  `total_replies` int(11) NOT NULL DEFAULT '0',
  `status` enum('healthy','banned','deleted') NOT NULL DEFAULT 'healthy',
  PRIMARY KEY (`topic_id`),
  KEY `last_update_date` (`last_update_date`),
  KEY `author_id` (`author_id`),
  KEY `forum_id` (`forum_id`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `upload`
--

CREATE TABLE IF NOT EXISTS `upload` (
  `upload_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(11) unsigned NOT NULL DEFAULT '0',
  `forum_id` int(11) unsigned NOT NULL DEFAULT '0',
  `filename` varchar(36) DEFAULT NULL,
  `filesize` double DEFAULT NULL,
  `filetype` varchar(4) DEFAULT NULL,
  PRIMARY KEY (`upload_id`),
  KEY `upload_id` (`upload_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `user`
--

CREATE TABLE IF NOT EXISTS `user` (
  `user_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `username` varchar(32) NOT NULL,
  `password` varchar(32) NOT NULL DEFAULT '000000',
  `nickname` varchar(100) NOT NULL,
  `gender` enum('F','M','NA') NOT NULL DEFAULT 'NA',
  `email` varchar(255) NOT NULL,
  `register_time` int(11) unsigned NOT NULL DEFAULT '0',
  `register_ip` varchar(32) NOT NULL,
  `last_login_on` datetime DEFAULT NULL,
  `last_login_ip` varchar(32) DEFAULT NULL,
  `login_times` mediumint(8) unsigned NOT NULL DEFAULT '1',
  `status` enum('banned','blocked','verified','unverified','terminated') NOT NULL DEFAULT 'unverified',
  `threads` int(11) unsigned NOT NULL DEFAULT '0',
  `replies` int(11) unsigned NOT NULL DEFAULT '0',
  `lang` char(2) DEFAULT 'cn',
  `country` char(2) DEFAULT 'cn',
  `state_id` int(11) unsigned NOT NULL DEFAULT '0',
  `city_id` int(11) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`user_id`),
  UNIQUE KEY `email` (`email`),
  UNIQUE KEY `username` (`username`),
  KEY `register_time` (`register_time`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `user_activation`
--

CREATE TABLE IF NOT EXISTS `user_activation` (
  `user_id` int(11) unsigned NOT NULL DEFAULT '0',
  `activation_code` varchar(12) DEFAULT NULL,
  `new_email` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`user_id`),
  KEY `user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `user_forum`
--

CREATE TABLE IF NOT EXISTS `user_forum` (
  `user_id` int(11) unsigned NOT NULL DEFAULT '0',
  `forum_id` int(11) unsigned NOT NULL DEFAULT '0',
  `status` ENUM( 'admin', 'moderator', 'user', 'blocked', 'pending', 'rejected' ) NOT NULL DEFAULT 'user',
  `time` int(11) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`user_id`,`forum_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `user_details`
--

CREATE TABLE IF NOT EXISTS `user_details` (
  `user_id` int(11) unsigned NOT NULL DEFAULT '0',
  `qq` varchar(14) DEFAULT NULL,
  `msn` varchar(64) DEFAULT NULL,
  `yahoo` varchar(64) DEFAULT NULL,
  `skype` varchar(64) DEFAULT NULL,
  `gtalk` varchar(64) DEFAULT NULL,
  `homepage` varchar(255) DEFAULT NULL,
  `birthday` date DEFAULT NULL,
  PRIMARY KEY (`user_id`),
  KEY `user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `user_profile_photo`
--

CREATE TABLE IF NOT EXISTS `user_profile_photo` (
  `user_id` int(11) unsigned NOT NULL DEFAULT '0',
  `type` enum('upload','url') NOT NULL DEFAULT 'upload',
  `value` varchar(255) NOT NULL DEFAULT '0',
  `width` smallint(6) unsigned NOT NULL DEFAULT '0',
  `height` smallint(6) unsigned NOT NULL DEFAULT '0',
  `time` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `user_role`
--

CREATE TABLE IF NOT EXISTS `user_role` (
  `user_id` int(11) unsigned NOT NULL DEFAULT '0',
  `role` enum('admin','moderator','user','blocked','pending','rejected') DEFAULT 'user',
  `field` varchar(32) NOT NULL DEFAULT '',
  KEY `user_id` (`user_id`),
  KEY `field` (`field`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `user_settings`
--

CREATE TABLE IF NOT EXISTS `user_settings` (
  `user_id` int(11) unsigned NOT NULL DEFAULT '0',
  `type` varchar(48) NOT NULL,
  `value` varchar(48) NOT NULL,
  PRIMARY KEY (`user_id`,`type`),
  KEY `user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `variables`
--

CREATE TABLE IF NOT EXISTS `variables` (
  `type` enum('global','log') NOT NULL DEFAULT 'global',
  `name` varchar(32) NOT NULL DEFAULT '',
  `value` varchar(255) NOT NULL DEFAULT '',
  PRIMARY KEY (`type`,`name`),
  KEY `type` (`type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `visit`
--

CREATE TABLE IF NOT EXISTS `visit` (
  `user_id` int(11) unsigned NOT NULL DEFAULT '0',
  `object_type` varchar(12) NOT NULL DEFAULT '',
  `object_id` int(11) unsigned NOT NULL DEFAULT '0',
  `time` int(10) NOT NULL DEFAULT '0',
  PRIMARY KEY (`user_id`,`object_type`,`object_id`),
  KEY `user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
