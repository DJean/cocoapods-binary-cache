# Copyright 2019 Grabtaxi Holdings PTE LTE (GRAB), All rights reserved.
# Use of this source code is governed by an MIT-style license that can be found in the LICENSE file

require_relative 'helper/path_utils'

class PrebuildOutput
  def initialize(prebuildSandbox)
    @sandbox = prebuildSandbox
  end

  def delta_dir
    return "#{@sandbox.root}/../_Prebuild_delta"
  end

  def delta_file_path
    return "#{delta_dir}/changes.txt"
  end

  def clean_delta_file
    puts "clean_delta_file: #{delta_file_path}"
    FileUtils.remove_entry(delta_file_path, force=true)
  end

  def create_dir_if_needed(dir)
    FileUtils.mkdir_p dir unless File.directory?(dir)
  end

  # Input 2 arrays of library names
  def write_delta_file(updated, deleted)
    if !updated.empty? || !deleted.empty?
      create_dir_if_needed(delta_dir)
      file_path = delta_file_path
      File.open(file_path, 'w+') do |line|
        line.puts "Updated: #{updated}"
        line.puts "Deleted: #{deleted}"
      end
      puts "Pod prebuild changes were writen to file: #{file_path}"
    else
      puts "No changes in prebuild"
    end
  end

  def process_prebuilt_dev_pods
    devpod_output_path = "#{delta_dir}/devpod_prebuild_output/"
    create_dir_if_needed(devpod_output_path)
    puts "Copy prebuilt devpod frameworks to output dir: #{devpod_output_path}"

    # Inject project path (where the framework is built) to support generating code coverage later
    project_root = PathUtils.remove_last_path_component(@sandbox.standard_sanbox_path.to_s)
    template_file_path = devpod_output_path + "prebuilt_map"
    File.open(template_file_path, 'w') do |file|
      file.write(project_root)
    end

    Pod::Prebuild::CacheInfo.cache_miss_dev_pods_dic.each do |name, hash|
      puts "Output dev pod lib: #{name} hash: #{hash}"
      built_lib_path = @sandbox.framework_folder_path_for_target_name(name)
      if File.directory?(built_lib_path)
        FileUtils.cp(template_file_path, "#{built_lib_path}/#{name}.framework")

        target_dir = "#{devpod_output_path}#{name}_#{hash}"
        puts "From: #{built_lib_path} -> #{target_dir}"
        FileUtils.cp_r(built_lib_path, target_dir)
      end
    end
    
  end
end