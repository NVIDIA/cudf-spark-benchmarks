WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '1996-01-01' AND o.o_orderdate <= '1997-12-31'
), SupplierPartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ps.ps_supplycost,
        ps.ps_availqty,
        s.s_name,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS supplier_rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        p.p_retailprice > 100.00
), OrderLineItemStats AS (
    SELECT 
        lo.l_orderkey,
        SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS total_revenue,
        COUNT(lo.l_orderkey) AS line_count
    FROM 
        lineitem lo
    WHERE 
        lo.l_shipdate > '1997-01-01'
    GROUP BY 
        lo.l_orderkey
)

SELECT 
    o.o_orderkey,
    o.o_orderdate,
    o.o_totalprice,
    CASE 
        WHEN o.o_orderstatus = 'F' THEN 'Finished'
        WHEN o.o_orderstatus = 'P' THEN 'Pending'
        ELSE 'Other'
    END AS order_status_description,
    COALESCE(r.line_count, 0) AS line_item_count,
    COALESCE(r.total_revenue, 0.00) AS total_revenue,
    COUNT(sd.p_partkey) AS sup_part_count
FROM 
    RankedOrders o
LEFT JOIN 
    OrderLineItemStats r ON o.o_orderkey = r.l_orderkey
LEFT JOIN 
    SupplierPartDetails sd ON sd.supplier_rank = 1
WHERE 
    o.order_rank <= 5
GROUP BY 
    o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_orderstatus, r.line_count, r.total_revenue
ORDER BY 
    o.o_orderdate DESC, o.o_totalprice DESC;