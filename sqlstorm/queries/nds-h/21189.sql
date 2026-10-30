
WITH RankedCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY c.c_acctbal DESC) AS rn
    FROM 
        customer c
    WHERE 
        c.c_acctbal > 1000
), HighSpendOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        o.o_custkey,
        RANK() OVER (ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o 
    WHERE 
        o.o_totalprice IS NOT NULL
), SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COALESCE(SUM(ps.ps_supplycost), 0) AS total_supply_cost
    FROM 
        supplier s 
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), RecentOrderDetails AS (
    SELECT 
        li.l_orderkey,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
        COUNT(DISTINCT li.l_linenumber) AS total_items,
        MAX(li.l_shipdate) AS last_shipdate
    FROM 
        lineitem li
    WHERE 
        li.l_shipdate >= DATE '1998-10-01' - INTERVAL '30 days'
    GROUP BY 
        li.l_orderkey
)
SELECT 
    rc.c_name,
    COALESCE(rp.p_name, 'Unknown') AS product_name,
    rd.total_revenue,
    rd.total_items,
    sd.total_supply_cost,
    CASE 
        WHEN rd.last_shipdate IS NULL THEN 'No shipment'
        WHEN rd.last_shipdate < DATE '1998-10-01' - INTERVAL '15 days' THEN 'Delayed shipment'
        ELSE 'On time'
    END AS shipment_status
FROM 
    RankedCustomers rc
LEFT JOIN 
    HighSpendOrders ho ON rc.c_custkey = ho.o_custkey
LEFT JOIN 
    RecentOrderDetails rd ON ho.o_orderkey = rd.l_orderkey
LEFT JOIN 
    lineitem li ON rd.l_orderkey = li.l_orderkey
LEFT JOIN 
    part rp ON li.l_partkey = rp.p_partkey
LEFT JOIN 
    SupplierDetails sd ON li.l_suppkey = sd.s_suppkey
WHERE 
    rc.rn <= 5
    AND (rd.total_revenue IS NULL OR rd.total_revenue > 500)
ORDER BY 
    rc.c_name, rd.total_revenue DESC
LIMIT 10;
