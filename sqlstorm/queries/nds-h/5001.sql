WITH SupplierPartDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        p.p_name, 
        ps.ps_availqty, 
        ps.ps_supplycost, 
        ps.ps_comment 
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
), 
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        o.o_orderkey, 
        o.o_totalprice, 
        COUNT(l.l_orderkey) AS lineitem_count 
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O' 
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice
), 
RegionPurchaseAnalysis AS (
    SELECT 
        r.r_name, 
        SUM(o.o_totalprice) AS total_revenue 
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        r.r_name
) 
SELECT 
    spd.s_name AS supplier_name, 
    spd.p_name AS part_name, 
    spd.ps_availqty AS available_quantity, 
    spd.ps_supplycost AS supply_cost, 
    cus.c_name AS customer_name, 
    ord.o_orderkey AS order_key, 
    ord.o_totalprice AS order_total_price, 
    rpa.r_name AS region_name, 
    rpa.total_revenue AS region_total_revenue 
FROM 
    SupplierPartDetails spd
JOIN 
    CustomerOrderSummary ord ON spd.s_suppkey = ord.o_orderkey
JOIN 
    RegionPurchaseAnalysis rpa ON spd.s_suppkey = rpa.total_revenue
JOIN 
    customer cus ON ord.c_custkey = cus.c_custkey
WHERE 
    spd.ps_availqty > 0
ORDER BY 
    rpa.total_revenue DESC, spd.s_name;
