require 'docker'
require 'json'
require 'semantic_logger'

module EDURange::Docker
    class InstanceImage
      include SemanticLogger::Loggable

      def self.find(instance)
        label_filter = {
          label: [
            "edu.range.instance=#{instance.name}",
            "edu.range.scenario=#{instance.scenario.name}",
          ]
        }
        Docker::Image.all(all: false, filters: [label_filter.to_json]).first
      end

      def self.dockerfile_contents(instance)
        Dockerfile.new(instance).render
      end

      def self.build instance
        logger.trace 'building image', instance: instance.name
        InstanceImage.with_docker_build_directory instance do |dir|
          Docker::Image.build_from_dir(dir.to_path, t: instance.name.downcase) # t is the image 'tag'
        end
      end

      def self.with_docker_build_directory instance
        tmp_dir_prefix = "edurange_docker_image_for_#{instance.name}_"
        Dir.mktmpdir tmp_dir_prefix do |dir|
          tmp_path = Pathname.new(dir)

          # add script files to tmp directory
          instance.scripts.each do |script|
            logger.trace(event: 'installing_script', script: script.name)
            script_path = tmp_path + script.name
            script_path.open('w') do |script_file|
              contents = script.contents_for instance
              # kind of ugly to have this here.
              if contents.include? "\r" then
                raise "script '#{script.name}' contains windows carriage returns"
              end
              script_file.write(contents)
            end
          end

          # add dockerfile to tmp directory
          dockerfile_path = tmp_path + 'Dockerfile'
          dockerfile_path.open('w') do |dockerfile|
            dockerfile.write(dockerfile_contents instance)
          end

          # build image from tmp directory
          yield tmp_path
        end
      end
    end
end
