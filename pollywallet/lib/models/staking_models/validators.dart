class Validators {
  Summary summary;
  List<Result> result;
  String status;

  Validators({this.summary, this.result, this.status});

  Validators.fromJson(Map<String, dynamic> json) {
    summary =
        json['summary'] != null ? new Summary.fromJson(json['summary']) : null;
    if (json['result'] != null) {
      result = new List<Result>();
      json['result'].forEach((v) {
        result.add(new Result.fromJson(v));
      });
    }
    status = json['status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.summary != null) {
      data['summary'] = this.summary.toJson();
    }
    if (this.result != null) {
      data['result'] = this.result.map((v) => v.toJson()).toList();
    }
    data['status'] = this.status;
    return data;
  }
}

class Summary {
  int limit;
  int offset;
  String sortBy;
  String direction;
  String searchStr;
  int total;
  int size;

  Summary(
      {this.limit,
      this.offset,
      this.sortBy,
      this.direction,
      this.searchStr,
      this.total,
      this.size});

  Summary.fromJson(Map<String, dynamic> json) {
    limit = json['limit'];
    offset = json['offset'];
    sortBy = json['sortBy'];
    direction = json['direction'];
    searchStr = json['searchStr'];
    total = json['total'];
    size = json['size'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['limit'] = this.limit;
    data['offset'] = this.offset;
    data['sortBy'] = this.sortBy;
    data['direction'] = this.direction;
    data['searchStr'] = this.searchStr;
    data['total'] = this.total;
    data['size'] = this.size;
    return data;
  }
}

class Result {
  int id;
  String name;
  String description;
  String owner;
  String signer;
  String activationEpoch;
  Null deactivationEpoch;
  Null jailEndEpoch;
  String url;
  Null logoUrl;
  int commissionPercent;
  String status;
  String uptimePercent;
  int selfStake;
  int delegatedStake;
  int totalReward;
  int claimedReward;
  int signatureMissCount;
  bool isInAuction;
  Null auctionAmount;
  String createdAt;
  String updatedAt;
  String contractAddress;
  String signerPublicKey;
  bool delegationEnabled;

  Result(
      {this.id,
      this.name,
      this.description,
      this.owner,
      this.signer,
      this.activationEpoch,
      this.deactivationEpoch,
      this.jailEndEpoch,
      this.url,
      this.logoUrl,
      this.commissionPercent,
      this.status,
      this.uptimePercent,
      this.selfStake,
      this.delegatedStake,
      this.totalReward,
      this.claimedReward,
      this.signatureMissCount,
      this.isInAuction,
      this.auctionAmount,
      this.createdAt,
      this.updatedAt,
      this.contractAddress,
      this.signerPublicKey,
      this.delegationEnabled});

  Result.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    description = json['description'];
    owner = json['owner'];
    signer = json['signer'];
    activationEpoch = json['activationEpoch'];
    deactivationEpoch = json['deactivationEpoch'];
    jailEndEpoch = json['jailEndEpoch'];
    url = json['url'];
    logoUrl = json['logoUrl'];
    commissionPercent = json['commissionPercent'];
    status = json['status'];
    uptimePercent = json['uptimePercent'];
    selfStake = json['selfStake'];
    delegatedStake = json['delegatedStake'];
    totalReward = json['totalReward'];
    claimedReward = json['claimedReward'];
    signatureMissCount = json['signatureMissCount'];
    isInAuction = json['isInAuction'];
    auctionAmount = json['auctionAmount'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    contractAddress = json['contractAddress'];
    signerPublicKey = json['signerPublicKey'];
    delegationEnabled = json['delegationEnabled'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['description'] = this.description;
    data['owner'] = this.owner;
    data['signer'] = this.signer;
    data['activationEpoch'] = this.activationEpoch;
    data['deactivationEpoch'] = this.deactivationEpoch;
    data['jailEndEpoch'] = this.jailEndEpoch;
    data['url'] = this.url;
    data['logoUrl'] = this.logoUrl;
    data['commissionPercent'] = this.commissionPercent;
    data['status'] = this.status;
    data['uptimePercent'] = this.uptimePercent;
    data['selfStake'] = this.selfStake;
    data['delegatedStake'] = this.delegatedStake;
    data['totalReward'] = this.totalReward;
    data['claimedReward'] = this.claimedReward;
    data['signatureMissCount'] = this.signatureMissCount;
    data['isInAuction'] = this.isInAuction;
    data['auctionAmount'] = this.auctionAmount;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    data['contractAddress'] = this.contractAddress;
    data['signerPublicKey'] = this.signerPublicKey;
    data['delegationEnabled'] = this.delegationEnabled;
    return data;
  }
}