WITH RankedParts AS (
    SELECT
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(ps.ps_supplycost) DESC) AS rank
    FROM
        part p
    JOIN
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY
        p.p_partkey, p.p_name
),
SupplierNation AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(s.s_acctbal) AS total_acctbal
    FROM 
        supplier s
    JOIN
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY
        s.s_suppkey, s.s_name, n.n_name
)
SELECT
    rp.p_partkey,
    rp.p_name,
    rp.total_available,
    rp.total_supply_cost,
    sn.s_name,
    sn.nation_name,
    sn.total_acctbal
FROM
    RankedParts rp
JOIN
    partsupp ps ON rp.p_partkey = ps.ps_partkey
JOIN
    SupplierNation sn ON ps.ps_suppkey = sn.s_suppkey
WHERE
    rp.rank = 1
AND
    sn.total_acctbal > (SELECT AVG(s.s_acctbal) FROM supplier s)
ORDER BY
    rp.total_available DESC, sn.total_acctbal DESC
LIMIT 50;
