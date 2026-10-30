
WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        n.n_name AS nation, 
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_inventory_value
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
    HAVING 
        SUM(ps.ps_availqty) > 100
), CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 10000
), LineItemStats AS (
    SELECT 
        l.l_partkey,
        SUM(l.l_quantity) AS total_quantity,
        AVG(l.l_extendedprice) AS avg_price
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= DATE '1997-01-01'
    GROUP BY 
        l.l_partkey
)
SELECT 
    ps.part_name,
    ss.s_name AS supplier_name,
    cs.c_name AS customer_name,
    ls.total_quantity,
    ss.total_inventory_value,
    cs.total_spent
FROM 
    (SELECT p.p_name AS part_name, p.p_partkey FROM part p) ps
JOIN 
    SupplierSummary ss ON ps.p_partkey = ss.s_suppkey
JOIN 
    CustomerOrderSummary cs ON cs.total_spent > 10000
JOIN 
    LineItemStats ls ON ps.p_partkey = ls.l_partkey
ORDER BY 
    ss.total_inventory_value DESC, 
    cs.total_spent DESC
LIMIT 50;
