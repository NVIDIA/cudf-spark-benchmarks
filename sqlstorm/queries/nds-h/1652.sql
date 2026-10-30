WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
), PartSupplier AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
), HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        ps.total_available,
        ps.avg_supply_cost
    FROM 
        part p
    LEFT JOIN 
        PartSupplier ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_retailprice > 100.00 AND (ps.total_available IS NOT NULL OR ps.avg_supply_cost IS NOT NULL)
), OrderDetails AS (
    SELECT 
        lo.l_orderkey,
        SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS total_revenue
    FROM 
        lineitem lo
    WHERE 
        lo.l_shipdate >= DATE '1997-06-01'
    GROUP BY 
        lo.l_orderkey
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.c_name,
    r.o_totalprice,
    hp.p_name,
    hp.p_brand,
    hp.p_retailprice,
    CASE 
        WHEN hd.total_revenue IS NOT NULL THEN hd.total_revenue
        ELSE 0
    END AS total_revenue,
    CASE 
        WHEN r.order_rank <= 5 THEN 'Top Order'
        ELSE 'Regular Order'
    END AS order_category
FROM 
    RankedOrders r
LEFT JOIN 
    HighValueParts hp ON r.o_orderkey = hp.p_partkey
LEFT JOIN 
    OrderDetails hd ON r.o_orderkey = hd.l_orderkey
WHERE 
    r.o_totalprice > (SELECT AVG(o_totalprice) FROM orders) 
    OR hp.p_brand IS NOT NULL
ORDER BY 
    r.o_orderdate DESC, total_revenue DESC;