WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderdate < DATE '1997-12-31'
),
SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(ps.ps_supplycost) AS average_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
CustomerSales AS (
    SELECT 
        c.c_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_returnflag = 'N'
    GROUP BY 
        c.c_custkey
),
PartialResults AS (
    SELECT 
        r.r_name,
        ns.n_name,
        COUNT(DISTINCT cs.c_custkey) AS unique_customers,
        SUM(cs.total_sales) AS total_sales,
        SUM(ss.total_available_qty) AS total_available_qty,
        AVG(ss.average_supply_cost) AS avg_supply_cost
    FROM 
        region r
    LEFT JOIN 
        nation ns ON r.r_regionkey = ns.n_regionkey
    LEFT JOIN 
        SupplierSummary ss ON ns.n_nationkey = ss.s_suppkey
    LEFT JOIN 
        CustomerSales cs ON ns.n_nationkey = cs.c_custkey
    GROUP BY 
        r.r_name, ns.n_name
)
SELECT 
    pr.r_name,
    pr.n_name,
    pr.unique_customers,
    COALESCE(pr.total_sales, 0) AS total_sales,
    COALESCE(pr.total_available_qty, 0) AS total_available_qty,
    ROUND(pr.avg_supply_cost, 2) AS avg_supply_cost,
    o.o_orderkey,
    o.o_orderstatus
FROM 
    PartialResults pr
LEFT JOIN 
    RankedOrders o ON pr.r_name IS NOT NULL AND o.price_rank <= 10
WHERE 
    pr.unique_customers > 0
ORDER BY 
    pr.total_sales DESC, pr.r_name;