
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '6 months'
), SupplierStats AS (
    SELECT 
        ps.ps_partkey,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, s.s_nationkey
), CustomerSpend AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
), PartDetails AS (
    SELECT 
        p.p_partkey,
        MAX(p.p_retailprice) AS max_retail_price,
        MIN(p.p_size) AS min_size
    FROM 
        part p
    GROUP BY 
        p.p_partkey
)
SELECT 
    c.c_custkey,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice * (1 - l.l_discount) ELSE 0 END) AS total_returns,
    COALESCE(cs.total_spent, 0) AS total_customer_spent,
    COALESCE(ss.total_supply_cost, 0) AS total_supply_cost,
    pd.max_retail_price,
    pd.min_size
FROM 
    customer c
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    CustomerSpend cs ON c.c_custkey = cs.c_custkey
LEFT JOIN 
    SupplierStats ss ON l.l_partkey = ss.ps_partkey
LEFT JOIN 
    PartDetails pd ON l.l_partkey = pd.p_partkey
WHERE 
    c.c_acctbal > 100
    AND (pd.max_retail_price IS NOT NULL OR ss.total_supply_cost > 0)
GROUP BY 
    c.c_custkey, cs.total_spent, ss.total_supply_cost, pd.max_retail_price, pd.min_size
HAVING 
    SUM(l.l_quantity) > 10
ORDER BY 
    total_returns DESC, c.c_custkey;
