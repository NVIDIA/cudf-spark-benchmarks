WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        DENSE_RANK() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS rank,
        n.n_name AS nation_name,
        r.r_name AS region_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        (EXTRACT(YEAR FROM o.o_orderdate) = 1997 AND o.o_orderstatus = 'O') OR 
        (l.l_returnflag = 'R' AND l.l_shipdate > o.o_orderdate)
    GROUP BY 
        o.o_orderkey, o.o_totalprice, o.o_orderdate
),
SupplierSales AS (
    SELECT 
        ps.ps_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_supply_cost
    FROM 
        partsupp ps
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        ps.ps_suppkey
)
SELECT 
    rs.s_name,
    rs.nation_name,
    rs.rank,
    h.o_orderkey,
    h.o_totalprice,
    COALESCE(s.total_supply_cost, 0) AS total_supply_cost,
    CASE 
        WHEN h.total_sales > 10000 THEN 'High Sales'
        WHEN h.total_sales BETWEEN 5000 AND 10000 THEN 'Medium Sales'
        ELSE 'Low Sales'
    END AS sales_category
FROM 
    RankedSuppliers rs
FULL OUTER JOIN 
    HighValueOrders h ON rs.s_suppkey = h.o_orderkey
LEFT JOIN 
    SupplierSales s ON rs.s_suppkey = s.ps_suppkey
WHERE 
    (rs.rank <= 5 OR rs.rank IS NULL)
    AND (h.o_totalprice IS NOT NULL OR h.o_orderkey IS NULL)
ORDER BY 
    rs.rank, h.o_totalprice DESC NULLS LAST;