
WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_value,
        o.o_orderdate
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_totalprice, o.o_orderdate
), RegionSummary AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        SUM(os.order_value) AS total_order_value
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        OrderSummary os ON o.o_orderkey = os.o_orderkey
    GROUP BY 
        r.r_regionkey, r.r_name
)
SELECT 
    rs.r_name,
    rs.total_order_value,
    ss.s_name,
    ss.total_value,
    ss.part_count
FROM 
    RegionSummary rs
JOIN 
    SupplierSummary ss ON rs.total_order_value > ss.total_value
ORDER BY 
    rs.total_order_value DESC, ss.part_count DESC
LIMIT 10;
