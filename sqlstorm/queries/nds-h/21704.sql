
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_size BETWEEN 10 AND 20
),
SupplierRatio AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        AVG(s.s_acctbal) AS avg_acctbal
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
    HAVING 
        COUNT(DISTINCT ps.ps_partkey) > 0
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
    HAVING 
        COUNT(o.o_orderkey) > 5
),
FilteredLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_price
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY 
        l.l_orderkey
),
SubqueryWithNull AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        (SELECT COUNT(*)
         FROM customer c
         WHERE c.c_nationkey = n.n_nationkey AND c.c_acctbal IS NULL) AS null_acct_count
    FROM 
        nation n
)
SELECT 
    pp.p_name,
    pp.p_retailprice,
    sr.part_count,
    sr.total_supply_cost,
    co.order_count,
    fl.net_price,
    n.n_name,
    n.null_acct_count
FROM 
    RankedParts pp
INNER JOIN 
    SupplierRatio sr ON pp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_supplycost < 100)
LEFT JOIN 
    CustomerOrders co ON sr.part_count = co.order_count
LEFT JOIN 
    FilteredLineItems fl ON fl.l_orderkey = pp.p_partkey -- Correctly join FilteredLineItems
JOIN 
    SubqueryWithNull n ON n.null_acct_count > 0 
WHERE 
    pp.rn = 1 
ORDER BY 
    pp.p_retailprice DESC
LIMIT 10;  -- Standardized limit clause
