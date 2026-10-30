
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
), 
SupplierPartDetails AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        s.s_name,
        s.s_acctbal AS supplier_account_balance,
        p.p_name,
        p.p_retailprice,
        p.p_type
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
), 
OrderLineItemDetails AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_quantity,
        l.l_extendedprice,
        l.l_discount,
        l.l_tax
    FROM 
        lineitem l
    JOIN 
        RankedOrders ro ON l.l_orderkey = ro.o_orderkey
    WHERE 
        ro.order_rank <= 100
), 
TotalRevenueByPart AS (
    SELECT 
        sp.p_name,
        SUM(ol.l_extendedprice * (1 - ol.l_discount)) AS total_revenue
    FROM 
        OrderLineItemDetails ol
    JOIN 
        SupplierPartDetails sp ON ol.l_partkey = sp.ps_partkey
    GROUP BY 
        sp.p_name
)
SELECT 
    tr.p_name,
    tr.total_revenue,
    sp.s_name,
    sp.supplier_account_balance,
    ro.o_orderstatus
FROM 
    TotalRevenueByPart tr
JOIN 
    SupplierPartDetails sp ON tr.p_name = sp.p_name
JOIN 
    RankedOrders ro ON sp.ps_suppkey = ro.o_orderkey
WHERE 
    tr.total_revenue > 10000
ORDER BY 
    tr.total_revenue DESC, 
    sp.supplier_account_balance ASC;
