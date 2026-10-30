
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' 
        AND o.o_orderdate < DATE '1997-01-01'
),
SupplierCost AS (
    SELECT 
        ps.ps_partkey,
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, s.s_suppkey, s.s_name
),
CustomerDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        n.n_name AS nation
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        c.c_acctbal > 5000
),
OrderDetails AS (
    SELECT 
        lo.l_orderkey,
        SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS net_sales,
        COUNT(*) AS line_item_count
    FROM 
        lineitem lo
    WHERE 
        lo.l_shipdate >= DATE '1996-01-01' 
        AND lo.l_shipdate < DATE '1997-01-01'
    GROUP BY 
        lo.l_orderkey
)
SELECT 
    COALESCE(cd.c_name, 'Unknown Customer') AS customer_name,
    COALESCE(rd.o_orderkey, 0) AS order_key,
    COALESCE(CAST(rd.o_orderdate AS STRING), 'N/A') AS order_date,
    od.net_sales,
    sc.total_supply_cost,
    CASE 
        WHEN sc.total_supply_cost IS NOT NULL AND od.net_sales IS NOT NULL THEN od.net_sales - sc.total_supply_cost
        ELSE NULL 
    END AS profit_margin
FROM 
    CustomerDetails cd
LEFT JOIN 
    RankedOrders rd ON cd.c_custkey = rd.o_orderkey
LEFT JOIN 
    OrderDetails od ON rd.o_orderkey = od.l_orderkey
LEFT JOIN 
    SupplierCost sc ON od.l_orderkey = sc.ps_partkey
WHERE 
    ((cd.nation = 'USA' AND rd.order_rank <= 10) OR cd.c_acctbal IS NULL)
ORDER BY 
    profit_margin DESC NULLS LAST;
