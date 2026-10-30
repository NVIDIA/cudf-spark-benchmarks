
WITH HighValueOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o 
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1996-01-01' AND o.o_orderdate < '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 5000
),
SupplierStats AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        COUNT(DISTINCT ps.ps_partkey) AS supplied_parts,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank,
        s.s_nationkey
    FROM 
        supplier s 
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
)
SELECT 
    r.r_name, 
    COALESCE(h.total_value, 0) AS total_order_value,
    COALESCE(s.supplied_parts, 0) AS number_of_supplied_parts,
    COALESCE(s.total_supply_cost, 0) AS total_cost
FROM 
    region r 
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    (
        SELECT 
            n.n_nationkey, 
            SUM(hv.total_value) AS total_value
        FROM 
            HighValueOrders hv
        JOIN 
            customer c ON hv.o_orderkey = c.c_custkey
        JOIN 
            nation n ON c.c_nationkey = n.n_nationkey
        GROUP BY 
            n.n_nationkey
    ) h ON n.n_nationkey = h.n_nationkey
LEFT JOIN 
    (
        SELECT 
            s.s_nationkey, 
            COUNT(*) AS supplied_parts, 
            SUM(s.total_supply_cost) AS total_supply_cost
        FROM 
            SupplierStats s
        GROUP BY 
            s.s_nationkey
    ) s ON n.n_nationkey = s.s_nationkey
WHERE 
    r.r_name IS NOT NULL
ORDER BY 
    r.r_name, total_order_value DESC, number_of_supplied_parts DESC;
