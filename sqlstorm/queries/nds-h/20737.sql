
WITH RankedCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        c.c_acctbal, 
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY c.c_acctbal DESC) AS acct_rank
    FROM 
        customer c
    WHERE 
        c.c_acctbal IS NOT NULL
), 
SupplierPartInformation AS (
    SELECT 
        ps.ps_partkey,
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT s.s_nationkey) AS unique_nations
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, s.s_suppkey
), 
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        COUNT(l.l_orderkey) AS item_count,
        MIN(l.l_shipdate) AS earliest_shipdate
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F' 
        AND l.l_returnflag <> 'R'
    GROUP BY 
        o.o_orderkey
)

SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    r.r_name AS region_name,
    COALESCE(rc.acct_rank, 0) AS customer_rank,
    COALESCE(sp.total_cost, 0) AS supplier_total_cost,
    COALESCE(od.revenue, 0) AS order_revenue,
    CONCAT('Product ', p.p_name, ' costs: ', CAST(p.p_retailprice AS VARCHAR(20))) AS price_info
FROM 
    part p
LEFT JOIN 
    region r ON p.p_partkey % 5 = r.r_regionkey
LEFT JOIN 
    RankedCustomers rc ON p.p_partkey = rc.c_custkey
LEFT JOIN 
    SupplierPartInformation sp ON p.p_partkey = sp.ps_partkey
LEFT JOIN 
    OrderDetails od ON p.p_partkey = od.o_orderkey
WHERE 
    (sp.total_cost IS NULL OR sp.unique_nations > 1)
    AND (rc.acct_rank IS NOT NULL OR p.p_size < 30)
ORDER BY 
    p.p_partkey, 
    customer_rank DESC
LIMIT 100;
