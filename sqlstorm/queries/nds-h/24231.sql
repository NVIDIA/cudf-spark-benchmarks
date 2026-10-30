WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate > '1997-01-01'
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_availqty) AS total_available, 
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
CustomerDetails AS (
    SELECT 
        c.c_custkey,
        CASE 
            WHEN c.c_acctbal IS NULL THEN 'No Balance'
            ELSE CAST(c.c_acctbal AS STRING)
        END AS account_balance,
        c.c_mktsegment 
    FROM 
        customer c
    WHERE 
        c.c_mktsegment IN ('BUILDING', 'AUTOMOBILE') OR c.c_acctbal > 1000
),
PartDimensions AS (
    SELECT 
        p.p_partkey, 
        CASE 
            WHEN p.p_size IS NULL THEN 'Size Unknown'
            ELSE CAST(p.p_size AS STRING)
        END AS size_desc,
        p.p_retailprice
    FROM 
        part p
    WHERE 
        p.p_retailprice > 100
),
FilteredLineItems AS (
    SELECT 
        l.*, 
        ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_linenumber DESC) AS row_num
    FROM 
        lineitem l
    WHERE 
        l.l_discount BETWEEN 0.05 AND 0.10
)

SELECT 
    po.o_orderkey, 
    po.o_totalprice,
    ps.avg_supply_cost, 
    p.size_desc,
    COUNT(DISTINCT cl.c_custkey) AS customer_count,
    SUM(fli.l_extendedprice * (1 - fli.l_discount)) AS total_revenue
FROM 
    RankedOrders po
LEFT JOIN 
    SupplierStats ps ON po.o_orderkey = ps.s_suppkey
FULL OUTER JOIN 
    CustomerDetails cl ON cl.c_mktsegment = 'BUILDING'
INNER JOIN 
    PartDimensions p ON p.p_partkey = ps.s_suppkey
LEFT JOIN 
    FilteredLineItems fli ON fli.l_orderkey = po.o_orderkey AND fli.row_num = 1
WHERE 
    po.order_rank <= 5
AND 
    (cl.account_balance IS NOT NULL OR p.p_retailprice > 150)
GROUP BY 
    po.o_orderkey, po.o_totalprice, ps.avg_supply_cost, p.size_desc
HAVING 
    SUM(fli.l_extendedprice) IS NOT NULL
ORDER BY 
    po.o_totalprice DESC NULLS LAST;