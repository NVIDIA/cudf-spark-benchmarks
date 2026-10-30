WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        DENSE_RANK() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal IS NOT NULL AND s.s_acctbal > 0
),
PartOrders AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey, l.l_partkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
),
SupplierPartInfo AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_availqty,
        ps.ps_supplycost,
        p.p_name,
        RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost ASC) AS supply_rank
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
FilteredResults AS (
    SELECT 
        part_info.p_name,
        supplier.s_name,
        orders.o_orderkey,
        orders.o_orderstatus,
        COALESCE(part_order.total_sales, 0) AS total_sales
    FROM 
        SupplierPartInfo part_info
    JOIN 
        RankedSuppliers supplier ON part_info.ps_suppkey = supplier.s_suppkey
    LEFT JOIN 
        PartOrders part_order ON part_info.ps_partkey = part_order.l_partkey
    JOIN 
        orders ON part_order.l_orderkey = orders.o_orderkey
    WHERE 
        supplier.rank <= 3 
        AND (orders.o_orderstatus = 'O' OR orders.o_orderstatus IS NULL)
)
SELECT 
    p_name,
    s_name,
    COUNT(o_orderkey) AS total_orders,
    AVG(total_sales) AS avg_sales,
    SUM(total_sales) AS total_sales_all
FROM 
    FilteredResults
GROUP BY 
    p_name, s_name
HAVING 
    COUNT(o_orderkey) > 5 AND SUM(total_sales) IS NOT NULL
ORDER BY 
    p_name, total_sales_all DESC;
