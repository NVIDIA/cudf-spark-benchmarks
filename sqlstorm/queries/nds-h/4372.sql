
WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(ps.ps_partkey) AS total_parts_supported,
        SUM(ps.ps_availqty) AS total_available_quantity,
        AVG(ps.ps_supplycost) AS average_supply_cost
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY DATE_TRUNC('month', o.o_orderdate) ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'O'
),
NationRegionSales AS (
    SELECT 
        n.n_nationkey,
        r.r_regionkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        n.n_nationkey, r.r_regionkey
),
TopSales AS (
    SELECT 
        n.n_name,
        r.r_name,
        ns.total_sales
    FROM 
        NationRegionSales ns
    JOIN 
        nation n ON ns.n_nationkey = n.n_nationkey
    JOIN 
        region r ON ns.r_regionkey = r.r_regionkey
    WHERE 
        ns.total_sales > (SELECT AVG(total_sales) FROM NationRegionSales)
)
SELECT 
    s.s_name,
    s.total_parts_supported,
    s.total_available_quantity,
    s.average_supply_cost,
    t.n_name,
    t.r_name,
    t.total_sales
FROM 
    SupplierStats s
FULL OUTER JOIN 
    TopSales t ON s.total_parts_supported > 5
ORDER BY 
    s.average_supply_cost DESC NULLS LAST, 
    t.total_sales DESC NULLS LAST;
