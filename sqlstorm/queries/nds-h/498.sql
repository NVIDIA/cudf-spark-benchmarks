
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        EXTRACT(YEAR FROM o.o_orderdate) = 1997
),
SupplierCosts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        s.s_acctbal > 5000
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
HighValueItems AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_retailprice
    HAVING 
        SUM(COALESCE(ps.ps_availqty, 0)) > 100 OR COUNT(ps.ps_partkey) > 5
),
CustomerAggregates AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal IS NOT NULL
    GROUP BY 
        c.c_custkey
)
SELECT 
    p.p_name,
    p.p_retailprice,
    COALESCE(sc.total_supply_cost, 0) AS total_supply_cost,
    COALESCE(ca.total_spent, 0) AS total_spent,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(CASE WHEN li.l_returnflag = 'R' THEN 1 ELSE 0 END) AS total_returns
FROM 
    HighValueItems p
LEFT JOIN 
    SupplierCosts sc ON p.p_partkey = sc.ps_partkey
LEFT JOIN 
    lineitem li ON li.l_partkey = p.p_partkey
LEFT JOIN 
    orders o ON li.l_orderkey = o.o_orderkey
LEFT JOIN 
    CustomerAggregates ca ON o.o_custkey = ca.c_custkey
WHERE 
    p.supplier_count > 3 
    AND (sc.total_supply_cost IS NOT NULL OR COALESCE(ca.total_spent, 0) > 1000)
GROUP BY 
    p.p_name, p.p_retailprice, sc.total_supply_cost, ca.total_spent
ORDER BY 
    p.p_retailprice DESC, total_orders DESC;
