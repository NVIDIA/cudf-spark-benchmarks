WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrderDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= '1996-01-01'
),
LineItemAnalysis AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        COUNT(CASE WHEN l.l_returnflag = 'R' THEN 1 END) AS total_returns
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey, l.l_partkey
)
SELECT 
    p.p_name,
    COALESCE(CAST(SUM(cod.o_totalprice) AS DECIMAL(12, 2)), 0) AS total_customer_orders,
    COALESCE(RS.total_supply_cost, 0) AS total_supplied_costs,
    LIA.net_revenue,
    CASE 
        WHEN LIA.total_returns > 0 THEN 'Returns Exist'
        ELSE 'No Returns'
    END AS return_status
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    RankedSuppliers RS ON ps.ps_suppkey = RS.s_suppkey AND RS.rank = 1
LEFT JOIN 
    LineItemAnalysis LIA ON ps.ps_partkey = LIA.l_partkey
LEFT JOIN 
    CustomerOrderDetails cod ON cod.o_orderkey = LIA.l_orderkey
WHERE 
    p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
    AND p.p_size IN (SELECT DISTINCT p3.p_size FROM part p3 WHERE p3.p_container = 'BOX')
GROUP BY 
    p.p_name, RS.total_supply_cost, LIA.net_revenue, LIA.total_returns
ORDER BY 
    total_customer_orders DESC, total_supplied_costs DESC, return_status;