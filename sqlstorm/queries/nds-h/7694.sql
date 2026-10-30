WITH RevenueData AS (
    SELECT 
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate < DATE '1996-01-01'
    GROUP BY 
        n.n_name
),
SupplierData AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        ps.ps_supplycost AS supply_cost,
        ps.ps_availqty AS available_quantity
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal > 1000.00
)
SELECT 
    rd.nation_name,
    rd.total_revenue,
    rd.total_orders,
    sd.supplier_name,
    sd.part_name,
    sd.supply_cost,
    sd.available_quantity
FROM 
    RevenueData rd
JOIN 
    SupplierData sd ON rd.nation_name = (SELECT n.n_name 
                                          FROM nation n 
                                          JOIN customer c ON n.n_nationkey = c.c_nationkey  
                                          WHERE c.c_custkey IN (SELECT o.o_custkey 
                                                                FROM orders o 
                                                                WHERE o.o_orderdate >= DATE '1995-01-01' 
                                                                AND o.o_orderdate < DATE '1996-01-01')
                                          LIMIT 1)
ORDER BY 
    rd.total_revenue DESC, 
    sd.supply_cost ASC;
