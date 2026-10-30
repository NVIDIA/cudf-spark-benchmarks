WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderdate ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'O'
),
SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
HighValueSuppliers AS (
    SELECT 
        ss.s_suppkey,
        ss.s_name
    FROM 
        SupplierSummary ss
    WHERE 
        ss.total_supply_cost > (
            SELECT 
                AVG(total_supply_cost) 
            FROM 
                SupplierSummary
        )
),
FinalReport AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        c.c_name AS customer_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_sales,
        COUNT(DISTINCT s.s_suppkey) AS total_suppliers
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    LEFT JOIN 
        supplier s ON li.l_suppkey = s.s_suppkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        li.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
        AND EXISTS (
            SELECT 1 
            FROM HighValueSuppliers hvs 
            WHERE hvs.s_suppkey = s.s_suppkey
        )
    GROUP BY 
        r.r_name, n.n_name, c.c_name
)
SELECT 
    fr.region_name,
    fr.nation_name,
    fr.customer_name,
    fr.total_orders,
    fr.total_sales,
    fr.total_suppliers,
    CASE 
        WHEN fr.total_sales > 100000 THEN 'High Sales'
        WHEN fr.total_sales BETWEEN 50000 AND 100000 THEN 'Medium Sales'
        ELSE 'Low Sales'
    END AS sales_category
FROM 
    FinalReport fr
ORDER BY 
    fr.total_sales DESC
LIMIT 10;