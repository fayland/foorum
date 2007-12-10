-- phpMyAdmin SQL Dump
-- version 2.11.1-rc1
-- http://www.phpmyadmin.net
--
-- Host: localhost
-- Generation Time: Nov 27, 2007 at 04:15 AM
-- Server version: 5.0.21
-- PHP Version: 5.2.4

SET SQL_MODE="NO_AUTO_VALUE_ON_ZERO";

--
-- Database: `foorum`
--

-- --------------------------------------------------------

--
-- Table structure for table `banned_ip`
--

DROP TABLE IF EXISTS `banned_ip`;
CREATE TABLE IF NOT EXISTS `banned_ip` (
  `ip_id` int(11) unsigned NOT NULL auto_increment,
  `cidr_ip` varchar(20) NOT NULL default '',
  `time` int(11) unsigned NOT NULL default '0',
  PRIMARY KEY  (`ip_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `comment`
--

DROP TABLE IF EXISTS `comment`;
CREATE TABLE IF NOT EXISTS `comment` (
  `comment_id` int(11) unsigned NOT NULL auto_increment,
  `reply_to` int(11) unsigned NOT NULL default '0',
  `text` text NOT NULL,
  `post_on` datetime default NULL,
  `update_on` datetime default NULL,
  `post_ip` varchar(32) NOT NULL default '',
  `formatter` varchar(16) NOT NULL default 'ubb',
  `object_type` varchar(30) NOT NULL,
  `object_id` int(11) unsigned NOT NULL default '0',
  `author_id` int(11) unsigned NOT NULL default '0',
  `title` varchar(255) NOT NULL default '',
  `forum_id` int(11) unsigned NOT NULL default '0',
  `upload_id` int(11) unsigned NOT NULL default '0',
  PRIMARY KEY  (`comment_id`),
  KEY `comment_id` (`comment_id`),
  KEY `upload_id` (`upload_id`),
  KEY `author_id` (`author_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `email_setting`
--

DROP TABLE IF EXISTS `email_setting`;
CREATE TABLE IF NOT EXISTS `email_setting` (
  `user_id` int(11) unsigned NOT NULL default '0',
  `object_type` enum('comment','topic') NOT NULL default 'comment',
  `frequence` enum('daily','weekly','none') NOT NULL default 'daily',
  PRIMARY KEY  (`user_id`,`object_type`),
  KEY `user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `filter_word`
--

DROP TABLE IF EXISTS `filter_word`;
CREATE TABLE IF NOT EXISTS `filter_word` (
  `word` varchar(64) NOT NULL,
  `type` enum('username_reserved','forum_code_reserved','bad_email_domain','offensive_word','bad_word') NOT NULL default 'username_reserved',
  PRIMARY KEY  (`word`,`type`),
  KEY `word` (`word`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `forum`
--

DROP TABLE IF EXISTS `forum`;
CREATE TABLE IF NOT EXISTS `forum` (
  `forum_id` int(11) unsigned NOT NULL auto_increment,
  `forum_code` varchar(25) NOT NULL,
  `name` varchar(100) NOT NULL,
  `description` varchar(255) NOT NULL,
  `forum_type` varchar(16) NOT NULL,
  `policy` enum('public','private','protected') NOT NULL default 'public',
  `total_members` int(8) NOT NULL default '0',
  `total_topics` int(11) NOT NULL default '0',
  `total_replies` int(11) NOT NULL default '0',
  `last_post_id` int(11) unsigned NOT NULL default '0',
  `status` enum('healthy','banned','deleted') NOT NULL default 'healthy',
  PRIMARY KEY  (`forum_id`),
  UNIQUE KEY `forum_code` (`forum_code`),
  KEY `forum_id` (`forum_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `hit`
--

DROP TABLE IF EXISTS `hit`;
CREATE TABLE IF NOT EXISTS `hit` (
  `hit_id` int(11) unsigned NOT NULL auto_increment,
  `object_type` varchar(12) NOT NULL,
  `object_id` int(11) unsigned NOT NULL default '0',
  `hit_new` int(11) unsigned NOT NULL default '0',
  `hit_today` int(11) unsigned NOT NULL default '0',
  `hit_yesterday` int(11) unsigned NOT NULL default '0',
  `hit_weekly` int(11) unsigned NOT NULL default '0',
  `hit_monthly` int(11) unsigned NOT NULL default '0',
  `hit_all` int(11) unsigned NOT NULL default '0',
  `last_update_time` int(11) unsigned NOT NULL default '0',
  PRIMARY KEY  (`hit_id`),
  KEY `object` (`object_type`,`object_id`),
  KEY `object_type` (`object_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `log_action`
--

DROP TABLE IF EXISTS `log_action`;
CREATE TABLE IF NOT EXISTS `log_action` (
  `user_id` int(11) unsigned NOT NULL default '0',
  `action` varchar(24) default NULL,
  `object_type` varchar(12) default NULL,
  `object_id` int(11) default NULL,
  `time` timestamp NOT NULL default CURRENT_TIMESTAMP,
  `text` text,
  `forum_id` int(11) unsigned NOT NULL default '0',
  KEY `user_id` (`user_id`),
  KEY `forum_id` (`forum_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `log_error`
--

DROP TABLE IF EXISTS `log_error`;
CREATE TABLE IF NOT EXISTS `log_error` (
  `error_id` int(11) unsigned NOT NULL auto_increment,
  `level` enum('info','debug','warn','error','fatal') NOT NULL default 'debug',
  `text` text NOT NULL,
  `time` timestamp NOT NULL default CURRENT_TIMESTAMP,
  PRIMARY KEY  (`error_id`),
  KEY `level` (`level`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `log_path`
--

DROP TABLE IF EXISTS `log_path`;
CREATE TABLE IF NOT EXISTS `log_path` (
  `path_id` int(11) unsigned NOT NULL auto_increment,
  `session_id` varchar(72) default NULL,
  `user_id` int(11) unsigned NOT NULL default '0',
  `path` varchar(255) NOT NULL default '',
  `get` varchar(255) default NULL,
  `post` text,
  `time` timestamp NOT NULL default CURRENT_TIMESTAMP,
  `loadtime` double NOT NULL default '0',
  PRIMARY KEY  (`path_id`),
  KEY `path` (`path`),
  KEY `session_id` (`session_id`),
  KEY `user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `message`
--

DROP TABLE IF EXISTS `message`;
CREATE TABLE IF NOT EXISTS `message` (
  `message_id` int(11) unsigned NOT NULL auto_increment,
  `from_id` int(11) unsigned NOT NULL default '0',
  `to_id` int(11) unsigned NOT NULL default '0',
  `title` varchar(255) NOT NULL,
  `text` text NOT NULL,
  `post_on` datetime NOT NULL,
  `post_ip` varchar(32) NOT NULL default '',
  `from_status` enum('open','deleted') NOT NULL default 'open',
  `to_status` enum('open','deleted') NOT NULL default 'open',
  PRIMARY KEY  (`message_id`),
  KEY `message_id` (`message_id`),
  KEY `to_id` (`to_id`),
  KEY `from_id` (`from_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `message_unread`
--

DROP TABLE IF EXISTS `message_unread`;
CREATE TABLE IF NOT EXISTS `message_unread` (
  `message_id` int(11) unsigned NOT NULL default '0',
  `user_id` int(11) NOT NULL default '0',
  PRIMARY KEY  (`message_id`,`user_id`),
  KEY `message_id` (`message_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `poll`
--

DROP TABLE IF EXISTS `poll`;
CREATE TABLE IF NOT EXISTS `poll` (
  `poll_id` int(11) unsigned NOT NULL auto_increment,
  `forum_id` int(11) unsigned NOT NULL default '0',
  `author_id` int(11) unsigned NOT NULL default '0',
  `multi` enum('0','1') NOT NULL default '0',
  `anonymous` enum('0','1') NOT NULL default '0',
  `time` int(10) default NULL,
  `duration` int(10) default NULL,
  `vote_no` mediumint(8) unsigned NOT NULL default '0',
  `title` varchar(128) default NULL,
  `hit` int(11) unsigned NOT NULL default '0',
  PRIMARY KEY  (`poll_id`),
  KEY `poll_id` (`poll_id`),
  KEY `author_id` (`author_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `poll_option`
--

DROP TABLE IF EXISTS `poll_option`;
CREATE TABLE IF NOT EXISTS `poll_option` (
  `option_id` int(11) unsigned NOT NULL auto_increment,
  `poll_id` int(11) unsigned NOT NULL default '0',
  `text` varchar(255) default NULL,
  `vote_no` mediumint(8) unsigned NOT NULL default '0',
  PRIMARY KEY  (`option_id`),
  KEY `option_id` (`option_id`),
  KEY `poll_id` (`poll_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `poll_result`
--

DROP TABLE IF EXISTS `poll_result`;
CREATE TABLE IF NOT EXISTS `poll_result` (
  `option_id` int(11) unsigned NOT NULL default '0',
  `poll_id` int(11) unsigned NOT NULL default '0',
  `poster_id` int(11) unsigned NOT NULL default '0',
  `poster_ip` varchar(32) default NULL,
  KEY `poll_id` (`poll_id`),
  KEY `option_id` (`option_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `scheduled_email`
--

DROP TABLE IF EXISTS `scheduled_email`;
CREATE TABLE IF NOT EXISTS `scheduled_email` (
  `email_id` int(11) unsigned NOT NULL auto_increment,
  `email_type` varchar(24) default NULL,
  `processed` enum('Y','N') NOT NULL default 'N',
  `from_email` varchar(128) default NULL,
  `to_email` varchar(128) default NULL,
  `subject` text,
  `plain_body` text,
  `html_body` text,
  `time` timestamp NOT NULL default CURRENT_TIMESTAMP,
  PRIMARY KEY  (`email_id`),
  KEY `processed` (`processed`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `session`
--

DROP TABLE IF EXISTS `session`;
CREATE TABLE IF NOT EXISTS `session` (
  `id` char(72) NOT NULL default '',
  `session_data` text,
  `expires` int(11) default '0',
  `user_id` int(11) unsigned NOT NULL default '0',
  `path` varchar(255) default NULL,
  PRIMARY KEY  (`id`),
  KEY `user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `star`
--

DROP TABLE IF EXISTS `star`;
CREATE TABLE IF NOT EXISTS `star` (
  `user_id` int(11) unsigned NOT NULL default '0',
  `object_type` varchar(12) NOT NULL default '',
  `object_id` int(11) unsigned NOT NULL default '0',
  `time` int(10) NOT NULL default '0',
  PRIMARY KEY  (`user_id`,`object_id`,`object_type`),
  KEY `user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `stat`
--

DROP TABLE IF EXISTS `stat`;
CREATE TABLE IF NOT EXISTS `stat` (
  `stat_id` int(11) unsigned NOT NULL auto_increment,
  `stat_key` varchar(255) NOT NULL,
  `stat_value` bigint(21) NOT NULL default '0',
  `date` date NOT NULL,
  PRIMARY KEY  (`stat_id`),
  KEY `key` (`stat_key`),
  KEY `date` (`date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `topic`
--

DROP TABLE IF EXISTS `topic`;
CREATE TABLE IF NOT EXISTS `topic` (
  `topic_id` int(11) unsigned NOT NULL auto_increment,
  `forum_id` int(11) unsigned NOT NULL default '0',
  `title` varchar(255) default NULL,
  `closed` enum('0','1') NOT NULL default '0',
  `sticky` enum('0','1') NOT NULL default '0',
  `elite` enum('0','1') NOT NULL default '0',
  `hit` int(11) NOT NULL default '0',
  `last_updator_id` int(11) unsigned NOT NULL default '0',
  `last_update_date` datetime default NULL,
  `author_id` int(11) unsigned NOT NULL default '0',
  `total_replies` int(11) NOT NULL default '0',
  `status` enum('healthy','banned','deleted') NOT NULL default 'healthy',
  PRIMARY KEY  (`topic_id`),
  KEY `topic_id` (`topic_id`),
  KEY `last_updator_id` (`last_updator_id`),
  KEY `author_id` (`author_id`),
  KEY `forum_id` (`forum_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `upload`
--

DROP TABLE IF EXISTS `upload`;
CREATE TABLE IF NOT EXISTS `upload` (
  `upload_id` int(11) unsigned NOT NULL auto_increment,
  `user_id` int(11) unsigned NOT NULL default '0',
  `forum_id` int(11) unsigned NOT NULL default '0',
  `filename` varchar(36) default NULL,
  `filesize` double default NULL,
  `filetype` varchar(4) default NULL,
  PRIMARY KEY  (`upload_id`),
  KEY `upload_id` (`upload_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `user`
--

DROP TABLE IF EXISTS `user`;
CREATE TABLE IF NOT EXISTS `user` (
  `user_id` int(11) unsigned NOT NULL auto_increment,
  `username` varchar(32) NOT NULL,
  `password` varchar(32) NOT NULL default '000000',
  `nickname` varchar(100) NOT NULL,
  `gender` enum('F','M','NA') NOT NULL default 'NA',
  `email` varchar(255) NOT NULL,
  `register_on` date default NULL,
  `register_time` int(11) unsigned NOT NULL default '0',
  `register_ip` varchar(32) NOT NULL,
  `last_login_on` datetime default NULL,
  `last_login_ip` varchar(32) default NULL,
  `login_times` mediumint(8) unsigned NOT NULL default '1',
  `status` enum('banned','blocked','verified','unverified','terminated') NOT NULL default 'unverified',
  `threads` int(11) unsigned NOT NULL default '0',
  `replies` int(11) unsigned NOT NULL default '0',
  `last_post_id` int(11) unsigned NOT NULL default '0',
  `lang` char(2) default 'cn',
  `country` char(2) default 'cn',
  `state_id` int(11) unsigned NOT NULL default '0',
  `city_id` int(11) unsigned NOT NULL default '0',
  PRIMARY KEY  (`user_id`),
  UNIQUE KEY `email` (`email`),
  UNIQUE KEY `username` (`username`),
  KEY `register_time` (`register_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `user_activation`
--

DROP TABLE IF EXISTS `user_activation`;
CREATE TABLE IF NOT EXISTS `user_activation` (
  `user_id` int(11) unsigned NOT NULL default '0',
  `activation_code` varchar(12) default NULL,
  `new_email` varchar(255) default NULL,
  PRIMARY KEY  (`user_id`),
  KEY `user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `user_details`
--

DROP TABLE IF EXISTS `user_details`;
CREATE TABLE IF NOT EXISTS `user_details` (
  `user_id` int(11) unsigned NOT NULL default '0',
  `qq` varchar(14) default NULL,
  `msn` varchar(64) default NULL,
  `yahoo` varchar(64) default NULL,
  `skype` varchar(64) default NULL,
  `gtalk` varchar(64) default NULL,
  `homepage` varchar(255) default NULL,
  `birthday` date default NULL,
  PRIMARY KEY  (`user_id`),
  KEY `user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `user_profile_photo`
--

DROP TABLE IF EXISTS `user_profile_photo`;
CREATE TABLE IF NOT EXISTS `user_profile_photo` (
  `user_id` int(11) unsigned NOT NULL default '0',
  `type` enum('upload','url') NOT NULL default 'upload',
  `value` varchar(255) NOT NULL default '0',
  `width` smallint(6) unsigned NOT NULL default '0',
  `height` smallint(6) unsigned NOT NULL default '0',
  `time` int(11) NOT NULL default '0',
  PRIMARY KEY  (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `user_role`
--

DROP TABLE IF EXISTS `user_role`;
CREATE TABLE IF NOT EXISTS `user_role` (
  `user_id` int(11) unsigned NOT NULL default '0',
  `role` enum('admin','moderator','user','blocked','pending','rejected') default 'user',
  `field` varchar(32) NOT NULL default '',
  KEY `user_id` (`user_id`),
  KEY `field` (`field`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `variables`
--

DROP TABLE IF EXISTS `variables`;
CREATE TABLE IF NOT EXISTS `variables` (
  `type` enum('global','log') NOT NULL default 'global',
  `name` varchar(32) NOT NULL default '',
  `value` varchar(255) NOT NULL default '',
  PRIMARY KEY  (`type`,`name`),
  KEY `type` (`type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `visit`
--

DROP TABLE IF EXISTS `visit`;
CREATE TABLE IF NOT EXISTS `visit` (
  `user_id` int(11) unsigned NOT NULL default '0',
  `object_type` varchar(12) NOT NULL default '',
  `object_id` int(11) unsigned NOT NULL default '0',
  `time` int(10) NOT NULL default '0',
  PRIMARY KEY  (`user_id`,`object_type`,`object_id`),
  KEY `user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
