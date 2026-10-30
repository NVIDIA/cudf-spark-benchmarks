WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS price_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
      AND 
        o.o_orderstatus IN ('F', 'S')
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_qty,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts_supplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
DiscountedLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS discounted_revenue
    FROM 
        lineitem l
    WHERE 
        l.l_returnflag = 'N'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    r.n_name AS nation,
    COUNT(DISTINCT oo.o_orderkey) AS total_orders,
    COALESCE(SUM(dd.discounted_revenue), 0) AS total_discounted_revenue,
    AVG(sd.total_available_qty) AS avg_available_qty,
    MAX(oo.o_totalprice) AS max_order_total
FROM 
    RankedOrders oo
LEFT JOIN 
    nation r ON oo.o_orderkey IS NOT NULL
LEFT JOIN 
    DiscountedLineItems dd ON oo.o_orderkey = dd.l_orderkey
JOIN 
    SupplierDetails sd ON sd.unique_parts_supplied > 5
WHERE 
    oo.price_rank <= 10
GROUP BY 
    r.n_name
HAVING 
    MAX(oo.o_totalprice) > 100.00
ORDER BY 
    total_orders DESC, avg_available_qty ASC;