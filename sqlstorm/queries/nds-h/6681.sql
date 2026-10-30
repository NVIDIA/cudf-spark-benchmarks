
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, p.p_partkey
),
CustomerOrderDetails AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice,
        COUNT(DISTINCT l.l_orderkey) AS total_orders,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice
)
SELECT 
    r.r_name, 
    cs.c_name, 
    SUM(cs.total_revenue) AS total_revenue_generated,
    SUM(rs.total_supply_value) AS total_supply_value_provided,
    AVG(cs.o_totalprice) AS average_order_value
FROM 
    CustomerOrderDetails cs
JOIN 
    nation n ON cs.c_custkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    RankedSuppliers rs ON rs.s_suppkey = (SELECT s_suppkey FROM RankedSuppliers WHERE supplier_rank = 1 LIMIT 1)
GROUP BY 
    r.r_name, cs.c_name
ORDER BY 
    total_revenue_generated DESC, total_supply_value_provided DESC
LIMIT 10;
