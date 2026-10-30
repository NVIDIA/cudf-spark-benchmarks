
WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderAggregates AS (
    SELECT 
        o.o_orderkey, 
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_value,
        RANK() OVER (PARTITION BY o.o_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
HighValueOrders AS (
    SELECT 
        o.o_custkey AS custkey, 
        SUM(o.order_value) AS total_order_value
    FROM 
        OrderAggregates o
    WHERE 
        o.order_rank <= 5
    GROUP BY 
        o.o_custkey
),
RankedSuppliers AS (
    SELECT 
        sd.s_suppkey, 
        sd.s_name,
        sd.total_cost, 
        sd.part_count,
        ROW_NUMBER() OVER (ORDER BY sd.total_cost DESC) AS supplier_rank
    FROM 
        SupplierDetails sd
)
SELECT 
    r.r_name,
    hs.total_order_value,
    rs.s_name,
    rs.total_cost,
    rs.part_count
FROM 
    HighValueOrders hs
JOIN 
    customer c ON hs.custkey = c.c_custkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    RankedSuppliers rs ON c.c_nationkey = (SELECT n2.n_nationkey FROM nation n2 WHERE n2.n_name = 'USA')
WHERE 
    hs.total_order_value > (SELECT AVG(total_order_value) FROM HighValueOrders)
ORDER BY 
    hs.total_order_value DESC, 
    rs.total_cost DESC;
