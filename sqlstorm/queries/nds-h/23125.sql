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
        p.p_retailprice IS NOT NULL
        AND p.p_size BETWEEN 1 AND 50
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal > (
            SELECT AVG(s2.s_acctbal) 
            FROM supplier s2
            WHERE s2.s_acctbal IS NOT NULL
        )
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
    HAVING 
        COUNT(DISTINCT ps.ps_partkey) > 10
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        COUNT(DISTINCT l.l_linenumber) AS item_count,
        MAX(l.l_shipdate) AS latest_ship_date
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus IN ('O', 'F')
        AND l.l_returnflag = 'N'
    GROUP BY 
        o.o_orderkey
)
SELECT 
    p.p_name,
    r.r_name,
    s.s_name,
    od.total_price,
    od.item_count,
    od.latest_ship_date
FROM 
    RankedParts p
LEFT JOIN 
    HighValueSuppliers s ON s.part_count > 10
INNER JOIN 
    nation n ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = (SELECT MIN(o2.o_orderkey) FROM orders o2 WHERE o2.o_orderstatus = 'O')))
LEFT JOIN 
    region r ON r.r_regionkey = n.n_regionkey
JOIN 
    OrderDetails od ON od.o_orderkey = (SELECT MIN(o.o_orderkey) FROM orders o WHERE o.o_orderstatus = 'O')
WHERE 
    p.rank <= 3 
    AND (s.s_acctbal IS NOT NULL OR s.s_name IS NULL)
    AND r.r_comment LIKE '%important%'
ORDER BY 
    p.p_retailprice DESC NULLS LAST;
