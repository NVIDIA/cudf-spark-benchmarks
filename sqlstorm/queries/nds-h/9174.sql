WITH SupplyChain AS (
    SELECT 
        n.n_name AS nation_name,
        r.r_name AS region_name,
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        SUM(ps.ps_availqty) AS total_available,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s 
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        r.r_name LIKE 'Europe%'
    GROUP BY 
        n.n_name, r.r_name, s.s_name, p.p_name
), OrderDetails AS (
    SELECT 
        c.c_name AS customer_name,
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(DISTINCT l.l_orderkey) AS order_count
    FROM 
        customer c 
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_name, o.o_orderkey, o.o_orderdate
)

SELECT 
    sc.nation_name,
    sc.region_name,
    sc.supplier_name,
    sc.part_name,
    sc.total_available,
    sc.total_supply_cost,
    od.customer_name,
    od.order_count,
    od.total_order_value
FROM 
    SupplyChain sc
JOIN 
    OrderDetails od ON sc.nation_name = 'Germany' 
                    AND sc.total_supply_cost > 50000
ORDER BY 
    sc.region_name, od.total_order_value DESC
LIMIT 100;
