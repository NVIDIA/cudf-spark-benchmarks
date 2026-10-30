WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
    WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
), FilteredSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_nationkey,
        s.s_phone,
        s.s_acctbal,
        s.s_comment,
        n.n_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE n.n_name IN ('USA', 'Canada')
), PartSupplierComments AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_comment,
        RP.p_name,
        RP.p_brand,
        RP.price_rank
    FROM partsupp ps
    JOIN RankedParts RP ON ps.ps_partkey = RP.p_partkey
    WHERE RP.price_rank <= 5
)
SELECT 
    F.s_name,
    F.s_address,
    F.s_phone,
    F.s_acctbal,
    P.ps_comment
FROM FilteredSuppliers F
JOIN PartSupplierComments P ON F.s_suppkey = P.ps_suppkey
ORDER BY F.s_name, P.p_brand;
