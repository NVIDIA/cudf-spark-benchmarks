
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        c.c_nationkey,
        DENSE_RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_totalprice > (
            SELECT AVG(o2.o_totalprice)
            FROM orders o2
            WHERE o2.o_orderdate BETWEEN DATE '1994-01-01' AND DATE '1994-12-31'
        )
),
AggregatedLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        COUNT(*) AS line_item_count
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        CASE 
            WHEN p.p_retailprice IS NULL THEN 'Unknown Price' 
            ELSE 'Price Available' 
        END AS price_info
    FROM 
        part p
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_size IS NOT NULL)
),
NationAggregates AS (
    SELECT 
        n.n_regionkey,
        COUNT(*) AS nation_count,
        SUM(s.s_acctbal) AS total_acctbal
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_regionkey
)
SELECT 
    r.r_name,
    na.nation_count,
    na.total_acctbal,
    pf.price_info,
    hs.o_orderkey,
    hs.o_totalprice
FROM 
    region r
JOIN 
    NationAggregates na ON r.r_regionkey = na.n_regionkey
LEFT JOIN 
    HighValueOrders hs ON hs.c_nationkey = na.n_regionkey
JOIN 
    RankedSuppliers rs ON rs.rn = 1
LEFT JOIN 
    FilteredParts pf ON pf.p_partkey = (
        SELECT 
            ps.ps_partkey 
        FROM 
            partsupp ps 
        WHERE 
            ps.ps_availqty > (SELECT AVG(ps2.ps_availqty) FROM partsupp ps2)
        ORDER BY 
            ps.ps_supplycost 
        LIMIT 1
    )
WHERE 
    (na.nation_count >= 5 OR na.total_acctbal IS NULL)
    AND hs.o_totalprice IS NOT NULL
ORDER BY 
    r.r_name, hs.o_totalprice DESC;
