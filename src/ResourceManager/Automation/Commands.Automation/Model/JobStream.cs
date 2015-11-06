﻿// ----------------------------------------------------------------------------------
//
// Copyright Microsoft Corporation
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// http://www.apache.org/licenses/LICENSE-2.0
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// ----------------------------------------------------------------------------------

using System;
using System.Collections;
using System.Management.Automation;
using Microsoft.Azure.Commands.Automation.Common;

using AutomationManagement = Microsoft.Azure.Management.Automation;

namespace Microsoft.Azure.Commands.Automation.Model
{
    /// <summary>
    /// The Job Stream.
    /// </summary>
    public class JobStream
    {
        /// <summary>
        /// Initializes a new instance of the <see cref="JobStream"/> class.
        /// </summary>
        /// <param name="jobStream">
        /// The job stream.
        /// </param>
        /// <param name="resourceGroupName">
        /// The resource group name.
        /// </param>
        /// <param name="automationAccountName">
        /// The automation account name
        /// </param>
        /// <param name="jobId">
        /// The job Id
        /// </param>
        /// <exception cref="System.ArgumentException">
        /// </exception>
        public JobStream(AutomationManagement.Models.JobStream jobStream, string resourceGroupName, string automationAccountName, Guid jobId )
        {
            Requires.Argument("jobStream", jobStream).NotNull();

            this.JobStreamId = jobStream.Properties.JobStreamId;
            this.Type = jobStream.Properties.StreamType;
            this.Time = jobStream.Properties.Time;
            this.AutomationAccountName = automationAccountName;
            this.ResourceGroupName = resourceGroupName;
            this.Id = jobId;
            this.Text = jobStream.Properties.StreamText;

            if (!String.IsNullOrWhiteSpace(jobStream.Properties.Summary))
            {
                if (jobStream.Properties.Summary.Length > Constants.JobSummaryLength)
                {
                    this.Summary = jobStream.Properties.Summary.Substring(0, Constants.JobSummaryLength) + "...";
                }
                else
                {
                    this.Summary = jobStream.Properties.Summary;
                }
            }

            this.Value = new Hashtable(StringComparer.InvariantCultureIgnoreCase);
            foreach (var kvp in jobStream.Properties.Value)
            {
                this.Value.Add(kvp.Key, kvp.Value);
            }
        }

        /// <summary>
        /// Initializes a new instance of the <see cref="JobStream"/> class.
        /// </summary>
        public JobStream()
        {
        }

        /// <summary>
        /// Gets or sets the resource group name.
        /// </summary>
        public string ResourceGroupName { get; set; }

        /// <summary>
        /// Gets or sets the automation account name.
        /// </summary>
        public string AutomationAccountName { get; set; }

        /// <summary>
        /// Gets or sets the Job Id.
        /// </summary>
        public Guid Id { get; set; }

        /// <summary>
        /// Gets or sets the stream id
        /// </summary>
        public string JobStreamId { get; set; }

        /// <summary>
        /// Gets or sets the stream time.
        /// </summary>
        public DateTimeOffset Time { get; set; }

        /// <summary>
        /// Gets or sets the stream text.
        /// </summary>
        public string Text { get; set; }

        /// <summary>
        /// Gets or sets the summary.
        /// </summary>
        public string Summary { get; set; }

        /// <summary>
        /// Gets or sets the stream Type.
        /// </summary>
        public string Type { get; set; }

        /// <summary>
        /// Gets or sets the stream values.
        /// </summary>
        public Hashtable Value { get; set; }
    }
}
