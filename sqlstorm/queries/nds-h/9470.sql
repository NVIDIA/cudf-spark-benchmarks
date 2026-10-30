WITH SupplierCosts AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), 
OrderStats AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
), 
HighRevenueOrders AS (
    SELECT 
        os.o_orderkey, 
        os.total_revenue 
    FROM 
        OrderStats os 
    WHERE 
        os.total_revenue > (SELECT AVG(total_revenue) FROM OrderStats)
)
SELECT 
    sc.s_name, 
    sc.total_supply_cost, 
    COUNT(DISTINCT hro.o_orderkey) AS high_revenue_orders_count
FROM 
    SupplierCosts sc
JOIN 
    partsupp ps ON sc.s_suppkey = ps.ps_suppkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
JOIN 
    HighRevenueOrders hro ON l.l_orderkey = hro.o_orderkey
GROUP BY 
    sc.s_suppkey, sc.s_name, sc.total_supply_cost
ORDER BY 
    sc.total_supply_cost DESC 
LIMIT 10;