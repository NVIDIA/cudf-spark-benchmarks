WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_availqty) AS total_available_qty, 
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), 
CustomerSummary AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COUNT(o.o_orderkey) AS total_orders, 
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
), 
PartPurchases AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        SUM(l.l_quantity) AS total_quantity_sold, 
        SUM(l.l_extendedprice) AS total_revenue
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    ss.s_name AS supplier_name, 
    cs.c_name AS customer_name, 
    ps.p_name AS part_name, 
    ps.total_quantity_sold, 
    ps.total_revenue, 
    ss.total_available_qty, 
    ss.avg_supply_cost, 
    cs.total_orders, 
    cs.total_spent
FROM 
    SupplierSummary ss
JOIN 
    CustomerSummary cs ON ss.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps JOIN lineitem l ON ps.ps_partkey = l.l_partkey LIMIT 1)
JOIN 
    PartPurchases ps ON ps.total_quantity_sold > 1000
ORDER BY 
    ps.total_revenue DESC, cs.total_spent DESC
LIMIT 10;