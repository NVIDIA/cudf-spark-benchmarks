
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank
    FROM 
        part p
    WHERE 
        p.p_size > (
            SELECT AVG(p2.p_size) 
            FROM part p2
            WHERE p2.p_type LIKE '%brass%'
        )
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    INNER JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal > (
            SELECT AVG(s2.s_acctbal) 
            FROM supplier s2 
            GROUP BY s2.s_nationkey
        )
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
    HAVING 
        COUNT(DISTINCT ps.ps_partkey) >= 3
),
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderdate,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_amount
    FROM 
        orders o
    JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1998-10-01' - INTERVAL '30 days'
    GROUP BY 
        o.o_orderkey, o.o_custkey, o.o_orderdate
)
SELECT 
    p.p_brand,
    COUNT(DISTINCT ps.ps_partkey) AS total_parts,
    AVG(o.total_amount) AS average_order_value,
    RANK() OVER (ORDER BY AVG(o.total_amount) DESC) AS rank_by_order_value
FROM 
    RankedParts p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    RecentOrders o ON ps.ps_suppkey IN (SELECT s.s_suppkey FROM HighValueSuppliers s)
WHERE 
    p.rank <= 5 AND 
    p.p_retailprice IS NOT NULL AND 
    NOT EXISTS (
        SELECT 1 FROM supplier s 
        WHERE s.s_acctbal < 100 AND s.s_suppkey = ps.ps_suppkey
    )
GROUP BY 
    p.p_brand
ORDER BY 
    rank_by_order_value ASC;
