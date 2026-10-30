WITH RankedParts AS (
    SELECT
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_container,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank
    FROM
        part p
    WHERE
        p.p_retailprice > 100.00
),
SupplierInfo AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_address,
        n.n_name AS nation_name,
        s.s_phone,
        s.s_acctbal,
        s.s_comment,
        ROW_NUMBER() OVER (ORDER BY s.s_acctbal DESC) AS rank
    FROM
        supplier s
    JOIN
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE
        s.s_acctbal > 5000.00
)
SELECT
    rp.p_name,
    rp.p_brand,
    rp.p_retailprice,
    si.s_name AS supplier_name,
    si.nation_name,
    si.s_acctbal
FROM
    RankedParts rp
JOIN
    partsupp ps ON rp.p_partkey = ps.ps_partkey
JOIN
    SupplierInfo si ON ps.ps_suppkey = si.s_suppkey
WHERE
    rp.rank <= 5 AND si.rank <= 10
ORDER BY
    rp.p_brand, si.s_acctbal DESC;
